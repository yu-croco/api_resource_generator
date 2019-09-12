require "fileutils"

namespace :api do
  desc 'Create API resource'
  task generate: :environment do
    api_version = ENV['API'].to_i
    fail("Please specify 'API'") if api_version.blank?

    create_new_dirs(api_version)
    copy_previous_resource_to_new_dirs(api_version)
    write_in_routes(api_version)
  end

  desc 'Destroy API resource'
  task destroy: :environment do
    api_version = ENV['API'].to_i
    fail("Please specify 'API'") if api_version.blank?

    destroy_dirs(api_version)
    delete_in_text(api_version)
  end

  private

  # manage file paths to create/destroy
  def base_methods
    {
      controller_path: "app/controllers/api/",
      view_path: "app/views/api/",
      spec_path: "spec/requests/api/"
    }
  end

  base_methods.each do |method_name, path|
    define_method(method_name) do
      |api_version, custom=nil| Rails.root.join(path + suffix(api_version, custom))
    end
  end

  def suffix(api_version, custom=nil)
    "v#{api_version}/#{custom}"
  end

  def create_new_dirs(api_version)
    base_methods.values.each do |path|
      full_path = path + suffix(api_version)
      next if File.directory?(full_path)

      FileUtils.mkdir_p(full_path)
      FileUtils.chmod(0777, full_path)
    end
  end

  def destroy_dirs(api_version)
    base_methods.values.each do |path|
      full_path = path + suffix(api_version)
      FileUtils.rm_rf(full_path)
      auto_log("DELETED", full_path)
    end
  end

  def copy_previous_resource_to_new_dirs(api_version)
    base_methods.keys.each do |method|
      copy_files(api_version, method)
    end
  end

  def copy_files(api_version, method)
    target_path = send(method, api_version)
    prev_path = send(method, api_version - 1, '*')

    FileUtils.cp_r(Dir.glob(prev_path), target_path)
    auto_log('CREATED', target_path)
    replace_api_version(target_path, api_version)
  end

  # update API description in 
  def replace_api_version(target_path, api_version)
    Pathname.glob(target_path + '*').each do |path|
      if File.directory?(path)
        Pathname.glob(path + '*').each do |p|
          replace_text_body!(p, api_version)
        end
      else
        replace_text_body!(path, api_version)
      end
    end
  end

  def replace_text_body!(path, api_version)
    text_body = path.read
    text_body.gsub!(/V#{api_version - 1}/, "V#{api_version}")
    text_body.gsub!(/v#{api_version - 1}/, "v#{api_version}")
    path.write(text_body)
  end


  def auto_log(notice, target_path)
    puts "[#{notice}] #{target_path}"
  end

  def clear_route_path
    Rails.root.join('config/routes/clear.rb')
  end

  def write_in_routes(api_version)
    Pathname.glob(clear_route_path).each do |path|
      text_data = routing_instruction(api_version) + path.read
      path.write(text_data)
    end
    auto_log('UPDATED', clear_route_path)
  end

  def delete_in_text(api_version)
    Pathname.glob(clear_route_path).each do |path|
      text_body = path.read
      text_body.gsub!(routing_instruction(api_version), '')
      path.write(text_body)
    end
  end

  def routing_instruction(api_version)
    new_version = api_version
    prev_version = api_version - 1
    <<-EOS
# [CAUTION]
# ClearのAPIバージョン分けの性質上、前バージョンのディレクトリに存在する全てのリソースを新しいAPIバージョンのディレクトリで定義する必要があります。
# 以下のサンプルを元に対応してください。
#
# APIがv#{new_version}とv#{prev_version}でともに、v#{prev_version}の階層のControllerを使いたい場合
# Controllerは増やさずに、Routeのconstraintsを変更する
scope '/api/:version/contents',module: 'api/v#{prev_version}', constraints: {version: /(v#{prev_version}|v#{new_version})/}, defaults: {format: 'json'} do
  get    '/:id(.:format)', to: 'contents#show'
end

# APIのバージョン単位でアクセスしたい場合
# 新しいAPIバージョンのnamespace内に前バージョンの構成をコピペする

namespace 'api', defaults: {format: 'json'} do
  namespace 'v#{new_version}' do
    get    '/contents(.:format)' =>'contents#index'
  end
end

EOS
  end

end

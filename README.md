# API Resource Generator
- This is a rake task for Ruby on Rails to create API resources(Controller, View, RSpec) automatically as referring previous API version resources.
  - (e.g.) If you create API v10 with this rake task, the program will copy the resource of API v9 and create new resources at V10 directory.
- I careated it because I needed to copy & past and rewrite whole api version on resources when I created new API version resources.
- Please copy & past `main.rake` to your Rails application (/lib/tasks/api.rake) when you use it.
  - e.g. `bin/rake api_resource_generator:generate API=2`

# License
[MIT](https://en.wikipedia.org/wiki/MIT_License)

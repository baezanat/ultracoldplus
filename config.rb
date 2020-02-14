require "lib/path_helpers"
require "lib/image_helpers"

page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

set :url_root, ENV.fetch('BASE_URL')

ignore '/templates/*'

LOCALES = ENV['LANGS'].split(",").map(&:to_sym)
activate :i18n, langs: LOCALES, mount_at_root: LOCALES[0]

activate :asset_hash
activate :directory_indexes
activate :pagination
activate :inline_svg

activate :dato, token: ENV.fetch('DATO_API_TOKEN'), live_reload: true, preview: true

webpack_command =
  if build?
    "yarn run build"
  else
    "yarn run dev"
  end

activate :external_pipeline,
  name: :webpack,
  command: webpack_command,
  source: ".tmp/dist",
  latency: 1

configure :build do
  activate :minify_html do |html|
    html.remove_input_attributes = false
  end
  activate :search_engine_sitemap,
    default_priority: 0.5,
    default_change_frequency: 'weekly'
end

configure :development do
  activate :livereload
end

helpers do
  include PathHelpers
  include ImageHelpers

  # Custom helper to theme
  def site_nav_menu
    [
      dato.team,
      dato.news_page,
      dato.project_page,
      dato.publication,
    ] + dato.info_pages.each { |pg| pg }
  end
end

dato.tap do |dato|

  dato.projects.each do |project|
    proxy(
      "projects/#{project.slug}.html",
      'templates/project-article.html',
      locals: {project: project},
      ignore: true
    )
  end


#   paginate(
#     dato.articles.sort_by(&:published_at).reverse,
#     '/articles',
#     '/templates/articles.html'
#   )

#   MULTILANG SAMPLES
#
#   langs.each do |locale|
#     I18n.with_locale(locale) do
#       proxy "/#{locale}/index.html",
#         "/localizable/index.html",
#         locals: { page: dato.homepage },
#         locale: locale
#
#       proxy "/#{locale}/#{dato.about_page.slug}/index.html",
#         "/templates/about_page.html",
#         locals: { page: dato.about_page },
#         locale: locale
#
#       dato.aritcles.each do |article|
#         I18n.locale = locale
#         proxy "/#{locale}/articles/#{article.slug}/index.html", "/templates/article_template.html", :locals => { article: article }, ignore: true, locale: locale
#       end
#     end
#   end

#   langs.each do |locale|
#     I18n.with_locale(locale) do
#       I18n.locale = locale
#       paginate dato.articles.select{|a| a.published == true}.sort_by(&:date).reverse, "/#{I18n.locale}/articles", "/templates/articles.html", locals: { locale: I18n.locale }
#     end
#   end
# end

  LOCALES.each do |locale|
    I18n.with_locale(locale) do
      prefix = locale == LOCALES[0] ? "" : "/#{locale}"

      proxy "#{prefix}/index.html",
        "templates/homepage.html",
        locals: { page: dato.homepage },
        locale: locale
      proxy "#{prefix}/team/index.html",
        "templates/team.html",
        locals: { page: dato.team },
        locale: locale
      proxy "#{prefix}/news/index.html",
        "templates/news.html",
        locals: { page: dato.news_page },
        locale: locale
      proxy "#{prefix}/project/index.html",
        "templates/project.html",
        locals: { page: dato.project_page },
        locale: locale
      proxy "#{prefix}/publications/index.html",
        "templates/publications.html",
        locals: { page: dato.publication,
                  paper: dato.papers.sort_by(&:date).reverse },
        locale: locale
      
      dato.info_pages.each do |info_page|
        proxy(
          "#{prefix}/#{info_page.slug}/index.html",
          '/templates/homepage.html',
          locals: { page: info_page },
          locale:locale
        )
      end
      
    end
  end
end

proxy "site.webmanifest",
  "templates/site.webmanifest",
  :layout => false

proxy "browserconfig.xml",
  "templates/browserconfig.xml",
  :layout => false

proxy "/_redirects",
  "/templates/redirects.txt",
  :layout => false

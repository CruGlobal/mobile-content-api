FactoryBot.define do
  factory :resource_type do
    factory :tract_resource_type do
      name { "tract" }
      dtd_file { "tract.xsd" }
    end

    factory :lesson_resource_type do
      name { "lesson" }
      dtd_file { "lesson.xsd" }
    end

    factory :cyoa_resource_type do
      name { "cyoa" }
      dtd_file { "cyoa.xsd" }
    end

    factory :article_resource_type do
      name { "article" }
      dtd_file { "article.xsd" }
    end
  end
end

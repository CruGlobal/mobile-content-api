# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

page_13_structure = '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <hero>
    <heading>
      <content:text i18n-id="f9894df9-df1d-4831-9782-345028c6c9a2">one un-translated phrase</content:text>
    </heading>

    <content:paragraph>
      <content:text i18n-id="9deda19f-c3ee-42ed-a1eb-92423e543352">two un-translated phrase</content:text>
    </content:paragraph>

    <content:form>
      <content:text>These four points explain how to enter into a personal relationship with God and
        experience the life for which you were created.
      </content:text>
      <content:button type="url" url-i18n-id="9deda19f-c3ee-42ed-a1eb-92423e543353">
        <content:text>Label</content:text>
      </content:button>
    </content:form>
  </hero>
</page>'

page_13_custom_structure = '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <hero>
    <heading>
      <content:text i18n-id="f9894df9-df1d-4831-9782-345028c6c9a2">one un-translated phrase</content:text>
    </heading>

    <content:paragraph>
      <content:text i18n-id="9deda19f-c3ee-42ed-a1eb-92423e543352">two un-translated phrase</content:text>
    </content:paragraph>
  </hero>
</page>'

page_4_structure = '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <hero>
    <heading>
      <content:text i18n-id="1373aa60-6c3f-4c69-b5ad-acfa2c0e4540">one un-translated phrase</content:text>
    </heading>

    <content:paragraph>
      <content:text i18n-id="e68a67da-df02-493f-b138-661bfe120663">two un-translated phrase</content:text>
    </content:paragraph>

    <content:paragraph>
      <content:text>We are sinful and separated from God because of our sin.
      </content:text>
    </content:paragraph>
  </hero>
</page>'

is_there_god_structure = '<?xml version="1.0" encoding="UTF-8" ?>
<article xmlns="https://mobile-content-api.cru.org/xmlns/article">
</article>'

beyond_blind_faith_structure = '<?xml version="1.0" encoding="UTF-8" ?>
<article xmlns="https://mobile-content-api.cru.org/xmlns/article">
</article>'

tract = ResourceType.find_or_create_by!(name: 'tract', dtd_file: 'tract.xsd')
article = ResourceType.find_or_create_by!(name: 'article', dtd_file: 'article.xsd')

godtools = System.find_or_create_by!(name: 'GodTools')

kgp = Resource.find_or_create_by!(name: 'Knowing God Personally', resource_type: tract, abbreviation: 'kgp', onesky_project_id: 148_314, system: godtools,
                                  manifest: '<?xml version="1.0"?><manifest xmlns="https://mobile-content-api.cru.org/xmlns/manifest" xmlns:content="https://mobile-content-api.cru.org/xmlns/content"><title><content:text i18n-id="89a09d72-114f-4d89-a72c-ca204c796fd9">Knowing God Personally</content:text></title></manifest>')
satisfied = Resource.find_or_create_by!(name: 'Satisfied?', resource_type: tract, abbreviation: 'sat', system: godtools, onesky_project_id: 999_999)
every_student = Resource.find_or_create_by!(name: 'Questions About God', resource_type: article, abbreviation: 'es', system: godtools)

page_13 = Page.find_or_create_by!(filename: '13_FinalPage.xml', resource: kgp, structure: page_13_structure, position: 1)
page_4 = Page.find_or_create_by!(filename: '04_ThirdPoint.xml', resource: kgp, structure: page_4_structure, position: 0)

english = Language.find_or_create_by!(name: 'English', code: 'en')
german = Language.find_or_create_by!(name: 'German', code: 'de')
Language.find_or_create_by!(name: 'Slovak', code: 'sk')
chinese = Language.find_or_create_by!(name: 'Chinese', code: 'es')

Translation.find_or_create_by!(resource: kgp, language: english, version: 1, is_published: true)
Translation.find_or_create_by!(resource: kgp, language: german, version: 1, is_published: true)
german_kgp = Translation.find_or_create_by!(resource: kgp, language: german, version: 2)

CustomPage.find_or_create_by!(language: german, page: page_13, structure: page_13_custom_structure)

Translation.find_or_create_by!(resource: satisfied, language: english, version: 1, is_published: true)
Translation.find_or_create_by!(resource: satisfied, language: english, version: 2, is_published: true)
Translation.find_or_create_by!(resource: satisfied, language: english, version: 3)
Translation.find_or_create_by!(resource: satisfied, language: german, version: 1, is_published: true)
Translation.find_or_create_by!(resource: satisfied, language: german, version: 2, is_published: true)

Translation.find_or_create_by!(resource: kgp, language: chinese, version: 1, is_published: true)

TranslatedPage.find_or_create_by!(value: is_there_god_structure, resource: every_student, language: german)
TranslatedPage.find_or_create_by!(value: beyond_blind_faith_structure, resource: every_student, language: german)

AccessCode.find_or_create_by!(code: 123_456)

Attribute.find_or_create_by!(resource: kgp, key: 'Banner_Image', value: 'this is a location')
attribute = Attribute.find_or_create_by!(resource: kgp, key: 'translate_me', value: 'base language', is_translatable: true)

Attribute.find_or_create_by!(resource: satisfied, key: 'Another_Attribute', value: 'blah blah blah')

TranslatedAttribute.find_or_create_by!(parent_attribute: attribute, translation: german_kgp, value: 'german attribute')

View.find_or_create_by!(quantity: 550, resource: kgp)
View.find_or_create_by!(quantity: 718, resource: kgp)

Attachment.create!(resource: kgp, file: Rack::Test::UploadedFile.new('spec/fixtures/wall.jpg', 'image/png'), is_zipped: true)
Attachment.create!(resource: kgp, file: Rack::Test::UploadedFile.new('spec/fixtures/beal.jpg', 'image/png'))
Attachment.create!(resource: kgp, file: Rack::Test::UploadedFile.new('spec/fixtures/mobile_only.png', 'image/png'), is_zipped: true)
Attachment.create!(resource: kgp, file: Rack::Test::UploadedFile.new('spec/fixtures/web_mobile.png', 'image/png'))
Attachment.create!(resource: kgp, file: Rack::Test::UploadedFile.new('spec/fixtures/both.png', 'image/png'), is_zipped: true)

Destination.find_or_create_by!(url: 'myapi.org', route_id: '100', access_key_id: '12345', access_key_secret: 'hello, world!!')
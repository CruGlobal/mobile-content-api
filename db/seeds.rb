# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

godtools = System.find_or_create_by(name: 'GodTools')
every_student = System.find_or_create_by(name: 'EveryStudent')

kgp = Resource.find_or_create_by(name: 'Knowing God Personally', abbreviation: 'kgp', onesky_project_id: 148_314, system: godtools)
satisfied = Resource.find_or_create_by(name: 'Satisfied?', abbreviation: 'sat', onesky_project_id: 123_456, system: godtools)
is_there_god = Resource.find_or_create_by(name: 'Is There A God?', abbreviation: 'God?', onesky_project_id: 223_456, system: every_student)

page_13 = Page.find_or_create_by(filename: '13_FinalPage.xml',
                                 resource: kgp,
                                 structure: '<note><to>Tove</to><from>Jani</from><heading>Reminder</heading>'\
                                 '<body>Dont forget me this weekend!</body></note>')
Page.find_or_create_by(filename: '04_ThirdPoint.xml',
                       resource: kgp,
                       structure: '<note><to>Tove</to><from>Jani</from><heading>Reminder</heading>'\
                                 '<body>Dont forget me this weekend!</body></note>')
page_13_elements = [10]
page_13_elements.push('WEBSITES TO ASSIST YOU')
page_13_elements.push('Still not sure who Jesus is?')
page_13_elements.push('everystudent.com')
page_13_elements.push('Read the Bible')
page_13_elements.push('bible.com/bible/59/mrk.1')
page_13_elements.push('More about Christianity...')
page_13_elements.push('startingwithgod.com')
page_13_elements.push('Watch a film about Jesus')
page_13_elements.push('jesusfilm.org/watch/jesus.html/english.html')
page_13_elements.push('Email the above links')

page_13_elements.each do |e|
  TranslationElement.find_or_create_by(page: page_13, text: e)
end

english = Language.find_or_create_by(name: 'English', abbreviation: 'en')
german = Language.find_or_create_by(name: 'German', abbreviation: 'de')
Language.find_or_create_by(name: 'Slovak', abbreviation: 'sk')

Translation.find_or_create_by(resource: kgp, language: english, version: 1, is_published: true)
Translation.find_or_create_by(resource: kgp, language: german, version: 1, is_published: true)
german_kgp = Translation.find_or_create_by(resource: kgp, language: german, version: 2)

CustomPage.find_or_create_by(translation: german_kgp,
                             page: page_13,
                             structure: '<custom>This is some custom xml for one translation</custom>')

Translation.find_or_create_by(resource: satisfied, language: english, version: 1, is_published: true)
Translation.find_or_create_by(resource: satisfied, language: english, version: 2, is_published: true)
Translation.find_or_create_by(resource: satisfied, language: english, version: 3)
Translation.find_or_create_by(resource: satisfied, language: german, version: 1, is_published: true)
Translation.find_or_create_by(resource: satisfied, language: german, version: 2, is_published: true)

Translation.find_or_create_by(resource: is_there_god, language: english, version: 1, is_published: true)

AccessCode.find_or_create_by(code: 123_456)

Attribute.find_or_create_by(resource: kgp, key: 'Banner Image', value: 'this is a location')
attribute = Attribute.find_or_create_by(resource: kgp, key: 'translate me', value: 'base language', is_translatable: true)

TranslatedAttribute.find_or_create_by(parent_attribute: attribute, translation: german_kgp, value: 'german attribute')

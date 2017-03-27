# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

godtools = System.create(name: 'GodTools')

kgp = Resource.create(name: 'Knowing God Personally', abbreviation: 'kgp', onesky_project_id: 148314, system: godtools)

page_13 = Page.create(filename: '13_FinalPage.xml',
                      resource: kgp,
                      structure: '<note><to>Tove</to><from>Jani</from><heading>Reminder</heading>'\
                                 '<body>Dont forget me this weekend!</body></note>')
Page.create(filename: '04_ThirdPoint.xml',
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
  TranslationElement.create(page: page_13, text: e)
end

english = Language.create(name: 'English', abbreviation: 'en')
german = Language.create(name: 'German', abbreviation: 'de')
Language.create(name: 'Slovak', abbreviation: 'sk')

Translation.create(resource: kgp, language: english, version: 1, is_published: true)
Translation.create(resource: kgp, language: german, version: 1, is_published: true)
german_kgp = Translation.create(resource: kgp, language: german, version: 2)

TranslationPage.create(translation: german_kgp, page: page_13, structure: '<custom>This is some custom xml for one translation</custom>')

AccessCode.create(code: 123456)
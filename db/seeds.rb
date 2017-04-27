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
                                 structure: '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="http://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <hero>
    <heading>
      <content:text i18n-id="1">one un-translated phrase</content:text>
      <content:text i18n-id="2">two un-translated phrase</content:text>
    </heading>

    <base_xml_element>
      <content:text>These four points explain how to enter into a personal relationship with God and
        experience the life for which you were created.
      </content:text>
    </base_xml_element>
  </hero>
</page>')
page_4 = Page.find_or_create_by(filename: '04_ThirdPoint.xml',
                       resource: kgp,
                       structure: '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="http://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <hero>
    <heading>
      <content:text i18n-id="14">fourteen un-translated phrase</content:text>
      <content:text i18n-id="15">fifteen un-translated phrase</content:text>
    </heading>

    <base_xml_element>
      <content:text>We are sinful and separated from God because of our sin.
      </content:text>
    </base_xml_element>
  </hero>
</page>')
page_13_elements = []
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

page_4_elements = []
page_4_elements.push('JESUS IS GOD\'S ONLY SOLUTION FOR OUR SIN. ONLY THROUGH HIM CAN WE KNOW GOD AND RECEIVE HIS LOVE AND FORGIVENESS.')
page_4_elements.push('Jesus is God')
page_4_elements.push('Christ is the visible image of the invisible God. He existed before anything was created and is supreme over all creation.')
page_4_elements.push('- Colossians 1:15')
page_4_elements.push('Jesus Died In Our Place')
page_4_elements.push('Christ suffered for our sins once for all time. He never sinned, but he died for sinners to bring you home safely to God.')
page_4_elements.push('- 1 Peter 3:18a')
page_4_elements.push('Jesus Came Back to Life')
page_4_elements.push('During the forty days after his crucifixion, he appeared to the apostles ... and he proved to them in many ways he was actually alive.   - Acts 1:3a')
page_4_elements.push('His resurrection proved that he was God and that he had suffered the punishment we deserved in our place.')
page_4_elements.push('Jesus is the Only Way...')
page_4_elements.push('Jesus said, "I am the way, the truth and the life. No-one can come to the Father except through me."')
page_4_elements.push('- John 14:6')
page_4_elements.push('God Proves His Love...')
page_4_elements.push('For God loved the world so much that he gave his one and only Son, so that everyone who believes in him will not perish but have eternal life. - John 3:16')
page_4_elements.push('▲ - God  |  † - Jesus  |  ★ - Man')
page_4_elements.push('Although we deserve to be cut off from God forever, in his love God sent Jesus to pay the penalty for our sins by dying on the cross.')
page_4_elements.push('Through Jesus, God has bridged the gap that separates us from him, and provided a way for us to be forgiven and restored to relationship with him.')
page_4_elements.push('It\'s not enough just to know these points...')

page_4_elements.each do |e|
  TranslationElement.find_or_create_by(page: page_4, text: e)
end

english = Language.find_or_create_by(name: 'English', code: 'en')
german = Language.find_or_create_by(name: 'German', code: 'de')
Language.find_or_create_by(name: 'Slovak', code: 'sk')

Translation.find_or_create_by(resource: kgp, language: english, version: 1, is_published: true)
Translation.find_or_create_by(resource: kgp, language: german, version: 1, is_published: true)
german_kgp = Translation.find_or_create_by(resource: kgp, language: german, version: 2)

CustomPage.find_or_create_by(translation: german_kgp,
                             page: page_13,
                             structure: '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="http://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <hero>
    <heading>
      <content:text i18n-id="1">one un-translated phrase</content:text>
      <content:text i18n-id="2">two un-translated phrase</content:text>
    </heading>

    <custom_xml_element>
      <content:text>These four points explain how to enter into a personal relationship with God and
        experience the life for which you were created.
      </content:text>
    </custom_xml_element>
  </hero>
</page>')

Translation.find_or_create_by(resource: satisfied, language: english, version: 1, is_published: true)
Translation.find_or_create_by(resource: satisfied, language: english, version: 2, is_published: true)
Translation.find_or_create_by(resource: satisfied, language: english, version: 3)
Translation.find_or_create_by(resource: satisfied, language: german, version: 1, is_published: true)
Translation.find_or_create_by(resource: satisfied, language: german, version: 2, is_published: true)

Translation.find_or_create_by(resource: is_there_god, language: english, version: 1, is_published: true)

AccessCode.find_or_create_by(code: 123_456)

Attribute.find_or_create_by(resource: kgp, key: 'Banner Image', value: 'this is a location')
attribute = Attribute.find_or_create_by(resource: kgp, key: 'translate me', value: 'base language', is_translatable: true)

Attribute.find_or_create_by(resource: satisfied, key: 'Another Attribute', value: 'blah blah blah')

TranslatedAttribute.find_or_create_by(parent_attribute: attribute, translation: german_kgp, value: 'german attribute')

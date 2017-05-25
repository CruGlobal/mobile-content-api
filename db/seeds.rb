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

    <paragraph>
      <content:text i18n-id="9deda19f-c3ee-42ed-a1eb-92423e543352">two un-translated phrase</content:text>
    </paragraph>

    <form>
      <content:text>These four points explain how to enter into a personal relationship with God and
        experience the life for which you were created.
      </content:text>
    </form>
  </hero>
</page>'

page_13_custom_structure = '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <hero>
    <heading>
      <content:text i18n-id="f9894df9-df1d-4831-9782-345028c6c9a2">one un-translated phrase</content:text>
    </heading>

    <paragraph>
      <content:text i18n-id="9deda19f-c3ee-42ed-a1eb-92423e543352">two un-translated phrase</content:text>
    </paragraph>
  </hero>
</page>'

page_13_elements = ['everystudent.com', 'Read the Bible', 'bible.com/bible/59/mrk.1', 'More about Christianity...',
                    'startingwithgod.com', 'Watch a film about Jesus', 'jesusfilm.org/watch/jesus.html/english.html',
                    'Email the above links']

page_4_structure = '<?xml version="1.0" encoding="UTF-8" ?>
<page xmlns="https://mobile-content-api.cru.org/xmlns/tract"
      xmlns:content="https://mobile-content-api.cru.org/xmlns/content">
  <hero>
    <heading>
      <content:text i18n-id="1373aa60-6c3f-4c69-b5ad-acfa2c0e4540">one un-translated phrase</content:text>
    </heading>

    <paragraph>
      <content:text i18n-id="e68a67da-df02-493f-b138-661bfe120663">two un-translated phrase</content:text>
    </paragraph>

    <paragraph>
      <content:text>We are sinful and separated from God because of our sin.
      </content:text>
    </paragraph>
  </hero>
</page>'

page_4_elements = ['JESUS IS GOD\'S ONLY SOLUTION FOR OUR SIN. ONLY THROUGH HIM CAN WE KNOW GOD AND RECEIVE HIS LOVE AND FORGIVENESS.',
                   'Christ is the visible image of the invisible God. He existed before anything was created and is supreme over all creation.',
                   '- Colossians 1:15', 'Christ suffered for our sins once for all time. He never sinned, but he died for sinners to bring you home safely to God.',
                   '- 1 Peter 3:18a', 'Jesus Came Back to Life', 'During the forty days after his crucifixion, he appeared to the apostles ... and he proved to them in many ways he was actually alive.   - Acts 1:3a',
                   'His resurrection proved that he was God and that he had suffered the punishment we deserved in our place.', 'Jesus is the Only Way...',
                   'Jesus said, "I am the way, the truth and the life. No-one can come to the Father except through me."', '- John 14:6',
                   'God Proves His Love...', 'For God loved the world so much that he gave his one and only Son, so that everyone who believes in him will not perish but have eternal life. - John 3:16',
                   '▲ - God  |  † - Jesus  |  ★ - Man', 'Although we deserve to be cut off from God forever, in his love God sent Jesus to pay the penalty for our sins by dying on the cross.',
                   'Through Jesus, God has bridged the gap that separates us from him, and provided a way for us to be forgiven and restored to relationship with him.', 'It\'s not enough just to know these points...']

is_there_god_structure = '<item name="Is There a God?">Does God exist? Here are six straight-forward reasons to believe that God is really there.
By Marilyn Adamson at EveryStudent.com
Just once wouldn\'t you love for someone to simply show you the evidence for God\'s existence? No arm-twisting. No statements of, ' \
'"You just have to believe." Well, here is an attempt to candidly offer some of the reasons which suggest that God exists.</item>'


beyond_blind_faith_structure = '<item name="Beyond Blind Faith">
 Is Jesus God? Here is a picture of the life of Jesus Christ and why it\'s not blind faith to believe in him...
  By Paul E. Little
It is impossible for us to know conclusively whether God exists and what He is like unless He takes the initiative and reveals '\
'Himself. We must scan the horizon of history to see if there is any clue to God\'s revelation. There is one clear clue. In an '\
'obscure village in Palestine, 2,000 years ago, a Child was born in a stable. Today the entire world is still celebrating the birth of Jesus.</item>'

godtools = System.find_or_create_by!(name: 'GodTools')
every_student = System.find_or_create_by!(name: 'EveryStudent')

kgp = Resource.find_or_create_by!(name: 'Knowing God Personally', content_type: :tract, abbreviation: 'kgp', onesky_project_id: 148_314, system: godtools)
satisfied = Resource.find_or_create_by!(name: 'Satisfied?', content_type: :tract, abbreviation: 'sat', onesky_project_id: 123_456, system: godtools)
es_content = Resource.find_or_create_by!(name: 'EveryStudent content', content_type: :article, abbreviation: 'esc', system: every_student)

page_13 = Page.find_or_create_by!(filename: '13_FinalPage.xml', resource: kgp, structure: page_13_structure, position: 1)
page_4 = Page.find_or_create_by!(filename: '04_ThirdPoint.xml', resource: kgp, structure: page_4_structure, position: 0)

is_there_god = Page.find_or_create_by!(filename: 'Is_There_A_God.xml', resource: es_content, structure: is_there_god_structure, position: 0)
beyond_blind_faith = Page.find_or_create_by!(filename: 'Beyond_Blind_Faith.xml', resource: es_content, structure: beyond_blind_faith_structure, position: 1)

=begin

page_13_elements.each do |e|
  TranslationElement.find_or_create_by!(page: page_13, text: e)
end


page_4_elements.each do |e|
  TranslationElement.find_or_create_by!(page: page_4, text: e)
end
=end

english = Language.find_or_create_by!(name: 'English', code: 'en')
german = Language.find_or_create_by!(name: 'German', code: 'de')
Language.find_or_create_by!(name: 'Slovak', code: 'sk')

Translation.find_or_create_by!(resource: kgp, language: english, version: 1, is_published: true)
Translation.find_or_create_by!(resource: kgp, language: german, version: 1, is_published: true)
german_kgp = Translation.find_or_create_by!(resource: kgp, language: german, version: 2)

CustomPage.find_or_create_by!(translation: german_kgp, page: page_13, structure: page_13_custom_structure)

Translation.find_or_create_by!(resource: satisfied, language: english, version: 1, is_published: true)
Translation.find_or_create_by!(resource: satisfied, language: english, version: 2, is_published: true)
Translation.find_or_create_by!(resource: satisfied, language: english, version: 3)
Translation.find_or_create_by!(resource: satisfied, language: german, version: 1, is_published: true)
Translation.find_or_create_by!(resource: satisfied, language: german, version: 2, is_published: true)

Translation.find_or_create_by!(resource: es_content, language: english, version: 1, is_published: true)
german_es = Translation.find_or_create_by!(resource: es_content, language: german, version: 1, is_published: true)

TranslatedPage.find_or_create_by!(value: 'German translation of article Is There A God?', translation: german_es, page: is_there_god)
TranslatedPage.find_or_create_by!(value: 'German translation of article Beyond Blind Faith', translation: german_es, page: beyond_blind_faith)

AccessCode.find_or_create_by!(code: 123_456)

Attribute.find_or_create_by!(resource: kgp, key: 'Banner_Image', value: 'this is a location')
attribute = Attribute.find_or_create_by!(resource: kgp, key: 'translate_me', value: 'base language', is_translatable: true)

Attribute.find_or_create_by!(resource: satisfied, key: 'Another_Attribute', value: 'blah blah blah')

TranslatedAttribute.find_or_create_by!(parent_attribute: attribute, translation: german_kgp, value: 'german attribute')

View.find_or_create_by!(quantity: 550, resource: kgp)
View.find_or_create_by!(quantity: 718, resource: kgp)

Attachment.create!(resource: kgp, file: Rack::Test::UploadedFile.new('public/wall.jpg', 'image/png'), is_zipped: true)
Attachment.create!(resource: kgp, file: Rack::Test::UploadedFile.new('public/beal.jpg', 'image/png'))
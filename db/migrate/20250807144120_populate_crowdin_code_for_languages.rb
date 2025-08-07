class PopulateCrowdinCodeForLanguages < ActiveRecord::Migration[7.0]
  def up
    # Reload column information to ensure crowdin_code column is available
    Language.reset_column_information

    # Language mapping from coworker's code
    language_mapping = {
      "bs-BA" => "bs",
      "bo" => "bo-BT",
      "es" => "es-ES",
      "gu" => "gu-IN",
      "ht-HT" => "ht",
      "hy" => "hy-AM",
      "km-KH" => "km",
      "lt-LT" => "lt",
      "ml" => "ml-IN",
      "ne" => "ne-NP",
      "pa" => "pa-IN",
      "pt" => "pt-BR",
      "si" => "si-LK",
      "sr-ME" => "sr-CS",
      "sr-RS" => "sr",
      "te-IN" => "te",
      "ur" => "ur-PK",
      "zh-Hans" => "zh-CN",
      "zh-Hant" => "zh-TW"
    }

    language_mapping.each do |language_code, crowdin_code|
      language = Language.find_by(code: language_code)
      language&.update!(crowdin_code: crowdin_code)
    end

    # For languages not in the mapping, set crowdin_code to the same as code
    Language.where(crowdin_code: nil).update_all("crowdin_code = code")
  end

  def down
    Language.reset_column_information
    Language.update_all(crowdin_code: nil)
  end
end

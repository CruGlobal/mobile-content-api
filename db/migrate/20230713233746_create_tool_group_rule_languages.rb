class CreateToolGroupRuleLanguages < ActiveRecord::Migration[6.1]
  def change
    create_table :tool_group_rule_languages do |t|
      t.references :tool_group, null: false, foreign_key: true
      t.string :languages, array: true, default: []
      t.boolean :negative_rule, default: false

      t.timestamps
    end
  end
end

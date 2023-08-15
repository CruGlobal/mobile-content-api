class CreateRulePraxis < ActiveRecord::Migration[6.1]
  def change
    create_table :rule_praxis do |t|
      t.references :tool_group, null: false, foreign_key: true
      t.integer :openness, array: true, default: []
      t.integer :confidence, array: true, default: []
      t.boolean :negative_rule, default: false

      t.timestamps
    end
  end
end

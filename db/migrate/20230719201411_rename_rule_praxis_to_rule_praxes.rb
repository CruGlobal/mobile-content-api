class RenameRulePraxisToRulePraxes < ActiveRecord::Migration[6.1]
  def change
    rename_table :rule_praxis, :rule_praxes
  end
end

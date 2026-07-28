class ConvertResourceDefaultOrderLangToLanguageId < ActiveRecord::Migration[7.1]
  def up
    add_column :resource_default_orders, :language_id, :integer
    add_index :resource_default_orders, [:resource_id, :language_id], unique: true

    # Migrate data from lang to language_id by joining with languages table
    execute <<-SQL
      UPDATE resource_default_orders
      SET language_id = languages.id
      FROM languages
      WHERE LOWER(resource_default_orders.lang) = LOWER(languages.code)
    SQL

    if column_exists?(:resource_default_orders, :lang)
      remove_index :resource_default_orders, :lang
      remove_column :resource_default_orders, :lang
    end
  end

  def down
    add_column :resource_default_orders, :lang, :string

    execute <<-SQL
      UPDATE resource_default_orders
      SET lang = languages.code
      FROM languages
      WHERE resource_default_orders.language_id = languages.id
    SQL

    if index_exists?(
      :resource_default_orders,
      [:resource_id, :language_id]
    )
      remove_index :resource_default_orders,
        [:resource_id, :language_id]
    end

    remove_column :resource_default_orders, :language_id if column_exists?(
      :resource_default_orders,
      :language_id
    )

    add_index :resource_default_orders, :lang
  end
end

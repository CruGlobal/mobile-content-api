class FavoriteTool < ApplicationRecord
  belongs_to :user
  belongs_to :tool, class_name: "Resource"
end

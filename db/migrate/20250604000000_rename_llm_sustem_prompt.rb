# frozen_string_literal: true

# Renames the mis-typed llm_sustem_prompt column
class RenameLlmSustemPrompt < ActiveRecord::Migration[7.1]
  def change
    rename_column :trees, :llm_sustem_prompt, :llm_system_prompt
  end
end

# frozen_string_literal: true

# Builds JSON-ready data for a tree and user context.
class TreePresenter
  def initialize(tree, current_user)
    @tree = tree
    @user = current_user
  end

  def summary_data(known_ids)
    neighbor_ids, friend_ids, species_ids = relationship_ids
    base_data.merge(
      counts_hash(neighbor_ids, friend_ids, species_ids, known_ids)
    ).merge(tag_data)
  end

  def related_ids_data
    {
      neighbors: map_ids(@tree.neighbor_ids),
      friends: map_ids(@tree.friend_ids),
      same_species: map_ids(@tree.same_species_ids)
    }
  end

  def known_ids_for_user
    @user&.known_trees&.map(&:id) || []
  end

  private

  def relationship_ids
    [@tree.neighbor_ids, @tree.friend_ids, @tree.same_species_ids]
  end

  def counts_hash(neighbor_ids, friend_ids, species_ids, known_ids)
    {
      neighbor_total: neighbor_ids.length,
      neighbor_known: known_count(neighbor_ids, known_ids),
      friend_total: friend_ids.length,
      friend_known: known_count(friend_ids, known_ids),
      species_total: species_ids.length,
      species_known: known_count(species_ids, known_ids)
    }
  end

  def known_count(all_ids, known_ids)
    (all_ids & known_ids).length
  end

  def base_data
    {
      id: @tree.id,
      name: @tree.name,
      treedb_lat: @tree.treedb_lat,
      treedb_long: @tree.treedb_long
    }
  end

  def tag_data
    {
      tag_counts: @tree.tag_counts,
      user_tags: @tree.tags_for_user(@user)
    }
  end

  def map_ids(ids)
    ids.map { |id| tree_name_pair(id) }
  end

  def tree_name_pair(id)
    { id: id, name: Tree.find(id).name }
  end
end

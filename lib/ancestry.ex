defmodule Ancestry do
  @moduledoc """
  This is a macro that allows you to add Ancestry trees to your models.
  It uses a version of Materialized Path Pattern.
  In order to use it, you will need to create the following migration (example: message)
  
  $ mix ecto.gen.migration add_ancestry_to_messages

  defmodule MyApp.Repo.Migrations.AddAncestryToMessages do
    use Ecto.Migration

    def change do
      alter table(:messages) do
        add :ancestry, :text
        add :child_count, :integer, default: 0
      end
      create index(:messages, [:ancestry])
    end
  end

  In your model:

  defmodule MyApp.Message do
    use Ancestry, [repo: MyApp.Repo]

    schema "messages" do
      ...
      ancestry_schema
      ...
    end

    # Make sure that [:ancestry, :child_count, :parent_id] can be added to your model via a changeset
  end



  """
  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)
      import Ecto.Query

      @opts unquote(opts)
      @delimiter @opts[:delimiter] || "."
      @esc_delimiter Regex.escape(@delimiter)
      def delimiter, do: @delimiter
      @repo @opts[:repo] || raise "Ancestry expects :repo to be given"
      @module __MODULE__ |> Module.split |> List.last

      def handle_ancestry(%{changes: %{parent_id: parent_id}, data: %{ancestry: ancestry}} = changeset) do
        parent = @repo.get! __MODULE__, parent_id
        Ecto.Changeset.put_change(changeset, :ancestry, child_ancestry_for_parent(parent))
        |> prepare_changes(fn changeset ->
          if changeset.action == :update do
            unless is_nil(ancestry) do
              old_parent_id = ancestry_parent_id(ancestry)
              unless old_parent_id == "#{parent_id}" do
                # Decrement old parent
                from(m in __MODULE__,
                where: m.id == ^old_parent_id)
                |> changeset.repo.update_all(inc: [child_count: -1])
              end
            end
          end
          from(m in __MODULE__,
          where: m.id == ^parent_id)
          |> changeset.repo.update_all(inc: [child_count: 1])
          changeset
        end)
      end
      def handle_ancestry(changeset), do: changeset

      def add_parent(model, %{id: parent_id} = parent) do
        # Ensure that the model is up to date, if we dont lookup again, it may have stale ancestry
        model = @repo.get(__MODULE__, model.id)
        case ancestry_parent_id(model.ancestry) do
          nil -> add_new_parent(model, parent)
          old_parent_id when old_parent_id == parent_id -> {:ok, model}
          old_parent_id -> add_parent_remove_old_parent(model, parent, old_parent_id)
        end
      end

      defp add_parent_remove_old_parent(child, parent, old_parent_id) do
        {:ok, child} = @repo.transaction(fn ->
          @repo.update_all(from(m in __MODULE__, where: m.id == ^old_parent_id), inc: [child_count: -1])
          @repo.update_all(from(m in __MODULE__, where: m.id == ^parent.id), inc: [child_count: 1])
          changeset(child, %{ancestry: child_ancestry_for_parent(parent)}) |> @repo.update!
        end)
      end

      defp add_new_parent(child, parent) do
        {:ok, child} = @repo.transaction(fn ->
          @repo.update_all(from(m in __MODULE__, where: m.id == ^parent.id), inc: [child_count: 1])
          changeset(child, %{ancestry: child_ancestry_for_parent(parent)}) |> @repo.update!
        end)
      end

      def add_parent!(model, parent) do
        case add_parent(model, parent) do
          {:ok, ok} -> ok
          {:error, changeset} -> raise AncestryError, changeset: changeset
        end
      end

      @doc """
        Returns an Ecto.Queryable that will get direct children of a given node.

        Example:
          #{@module}{id: 1} <- root
          #{@module}{id: 2} <- child of #{@module}{id: 1}
          #{@module}{id: 3} <- child of #{@module}{id: 2}

          #{@module}.descendants(#{@module}{id: 1}) |> Repo.all
          => [#{@module}{id: 2}]

      """
      def children(%{ancestry: ancestry, id: id}) do
        ancestry = Regex.escape("#{ancestry}") <> "#{id}" <> @esc_delimiter <> "$"
        from(model in __MODULE__, where: fragment("? ~ ?", model.ancestry, ^ancestry))
      end

      @doc """
        Returns an Ecto.Queryable that will get all of the descendants of a given node.

        Example:
          #{@module}{id: 1} <- root
          #{@module}{id: 2} <- child of #{@module}{id: 1}
          #{@module}{id: 3} <- child of #{@module}{id: 2}

          #{@module}.descendants(#{@module}{id: 1}) |> Repo.all
          => [#{@module}{id: 2}, #{@module}{id: 3}]

      """
      def descendants(%{ancestry: ancestry, id: id}) when not is_nil(id) do
        ancestry = Regex.escape("#{ancestry}") <> "#{id}" <> @esc_delimiter
        from(model in __MODULE__, where: fragment("? ~ ?", model.ancestry, ^ancestry))
      end

      @doc """
        Returns the #{__MODULE__}.__struct__ that is the root of the given node.

        Example:
          #{@module}{id: 1} <- root
          #{@module}{id: 2} <- child of #{@module}{id: 1}
          #{@module}{id: 3} <- child of #{@module}{id: 2}

          #{@module}.root(#{@module}{id: 3})
          => #{@module}{id: 1}
      """
      def root(%{ancestry: nil} = root), do: root
      def root(%{ancestry: ancestry}) do
        root_id = ancestry |> String.split(@delimiter) |> hd
        @repo.one(from(m in __MODULE__, where: m.id == ^root_id))
      end

      @doc """
      Returns the #{__MODULE__}.__struct__ that is the parent of the given node.
      Returns nil if the node has no parent
      """
      def parent(%{ancestry: nil} = node), do: nil
      def parent(%{ancestry: ancestry}), do: @repo.get(__MODULE__, ancestry_parent_id(ancestry))

      @doc """
        Returns an Ecto.Queryable that returns the siblings for the given node.
        It also includes the given node.

        If the given node is a root node with children, only other root nodes with children are returned (including given node)
        If the given node is a childless root node, the returned query will be root nodes with children (excluding the given node)

        NO specific order is garunteed, but a Queryable is returned, so add your own if needed

        Example:
          #{@module}{id: 1} <- root
          #{@module}{id: 2} <- child of #{@module}{id: 1}
          #{@module}{id: 3} <- child of #{@module}{id: 1}
          #{@module}{id: 4} <- no children

          #{@module}.siblings(#{@module}{id: 3}) |> Repo.all
          => [#{@module}{id: 2}, #{@module}{id: 3}]

          #{@module}.siblings(#{@module}{id: 1}) |> Repo.all
          => [#{@module}{id: 1}]
      """
      def siblings(model, opts \\ [])
      def siblings(%{id: id, ancestry: nil}, opts) when not is_nil(id) do
        query = from(m in __MODULE__, where: is_nil(m.ancestry))
        case opts[:include_childless] do
          x when x in [false, nil] -> from(q in query, where: q.child_count > 0)
          _ -> query
        end
      end
      def siblings(%{id: id, ancestry: ancestry}, opts)
      when not is_nil(ancestry) and not is_nil(id) do
        query = from(m in __MODULE__, where: m.ancestry == ^ancestry)
      end

      @doc """
        Depth will return the node depth for the given node
        Root nodes are of depth 0
        Direct children of root nodes are depth 1
      """
      def depth(node), do: ancestor_ids(node) |> Enum.count

      @doc """
      This will return an array of ids that lead to given node (including the given node)
      Example: (root) -> (parent) -> (child)
      path_ids(root) -> [root_id]
      path_ids(parent) -> [root_id, parent_id]
      path_ids(child) -> [root_id, parent_id, child_id]
      """
      def path_ids(%{ancestry: nil} = node), do: [node.id]
      def path_ids(node), do: ancestor_ids(node) ++ [node.id]

      @doc """
      Ancestors_list is  a list of ids for a given node's ancestors (excluding given node)

      Example:
      #{@module}{id: 1} <- root
      #{@module}{id: 2} <- child of #{@module}{id: 1}
      #{@module}{id: 3} <- child of #{@module}{id: 2}

      #{@module}.siblings(#{@module}{id: 1}) -> []
      #{@module}.siblings(#{@module}{id: 2}) -> [1]
      #{@module}.siblings(#{@module}{id: 3}) -> [1,2]
      """
      def ancestor_ids(%{ancestry: ancestry}), do: ancestor_ids(ancestry)
      def ancestor_ids(ancestry) when ancestry in [nil, ""], do: []
      def ancestor_ids(ancestry) when is_binary(ancestry) do
         ancestry
         |> String.trim(@delimiter)
         |> String.split(@delimiter)
         |> Enum.map(&String.to_integer/1)
      end

      @doc """
        Return an Ecto.Queryable that returns the direct lineage from the given
        node to it's root (excluding the given node).

        Example:
          #{@module}{id: 1} <- root
          #{@module}{id: 2} <- child of #{@module}{id: 1}
          #{@module}{id: 3} <- child of #{@module}{id: 2}

          #{@module}.ancestors(#{@module}{id: 3}) |> Repo.all
          => [#{@module}{id: 2}, #{@module}{id: 1}]

          #{@module}.ancestors(#{@module}{id: 1}) |> Repo.all
          => []
      """
      def ancestors(%{id: id, ancestry: nil}), do: from(m in __MODULE__, where: false)
      def ancestors(%{id: id, ancestry: ancestry}) do
        ids = ancestor_ids(ancestry)
        from(m in __MODULE__, where: m.id in ^ids, order_by: [asc: m.id])
      end

      def ancestors!(%{id: id, ancestry: nil}), do: []
      def ancestors!(input), do: input |> ancestors |> @repo.all

      @doc """
        The subtree is a nested map with all the descendants of the given node
        #{@module}{id: 1} <- root
        #{@module}{id: 2} <- child of #{@module}{id: 1}
        #{@module}{id: 3} <- child of #{@module}{id: 2}
        #{@module}{id: 4} <- child of #{@module}{id: 2}

        #{@module}.subtree(#{@module}{id: 1})
        %{
          id: 1,
          children: [
            %{
              id: 2,
              children: [
                %{id: 3, children:[]},
                %{id: 4, children:[]}
              ]
            }
          ]
        }
      """
      def subtree(%{id: id}=mod) do
        child_map = descendants(mod) |> @repo.all |> child_map
        Map.put(mod, :children, children_for(mod, child_map))
      end

      # This creates a map of: %{ancestry => [children]}
      defp child_map(items), do: gen_child_map(items, %{})

      defp gen_child_map([], map), do: map
      defp gen_child_map([item|rest], map) do
        gen_child_map(rest, Map.update(map, item.ancestry, [item], fn arr -> arr ++ [item] end))
      end

      # This recursively grabs the children for an item from the child_map
      defp children_for([], _hash), do: []
      defp children_for(item, child_map) do
        lookup = "#{item.ancestry}" <> "#{item.id}" <> @delimiter
        for(child <- Map.get(child_map, lookup, []), do: Map.put(child, :children, children_for(child, child_map)))
      end

      defp ancestry_parent_id(nil), do: nil
      defp ancestry_parent_id(ancestry) do
        ancestry
        |> String.trim(@delimiter) |> String.split(@delimiter)
        |> List.last |> String.to_integer
      end

      defp child_ancestry_for_parent(%{id: id, ancestry: ancestry}), do: "#{ancestry}#{id}#{@delimiter}"
    end
  end

  defmacro ancestry_schema do
    quote do
      field :ancestry, :string, default: nil
      field :child_count, :integer, default: 0
      field :parent_id, :id, virtual: true
    end
  end
end

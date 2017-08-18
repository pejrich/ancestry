defmodule Ancestry.AncestryTest do
  use Ancestry.TestCase

  alias Ancesry.{Message}

  test "the truth" do
    mess = %Message{title: "Cool Message"}
    IO.puts "\n mess \n #{inspect mess} \n\n"
  end
end
#
# defmodule AncestryTest do
#   use Hawktalk.ConnCase
#
#   alias Hawktalk.{Message, Repo}
#
#   @delimiter Message.delimiter
#
#   setup do
#     room = insert(:room)
#     user = insert(:user)
#     parent = insert(:message, room: room, body: "Parent", user: user)
#     childless = insert(:message, room: room, body: "Childless", user: user)
#     child = insert(:message, room: room, body: "Child", user: user)
#       |> Message.add_parent!(parent)
#     child2 = insert(:message, room: room, body: "Child2", user: user)
#       |> Message.add_parent!(parent)
#     child_of_child = insert(:message, room: room, body: "Child of Child", user: user)
#       |> Message.add_parent!(child)
#
#     other_parent = insert(:message, room: room, body: "Parent2", user: user)
#     other_child = insert(:message, room: room, body: "Other Child", user: user)
#       |> Message.add_parent!(other_parent)
#     {:ok, user: user, room: room, parent: parent, child: child, child2: child2, child_of_child: child_of_child, childless: childless, other_parent: other_parent, other_child: other_child}
#   end
#
#   test "Has correct child_count", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child, childless: childless} do
#     assert Repo.get(Message, parent.id).child_count == 2
#     assert Repo.get(Message, child.id).child_count == 1
#     assert Repo.get(Message, child2.id).child_count == 0
#     assert Repo.get(Message, child_of_child.id).child_count == 0
#     assert Repo.get(Message, childless.id).child_count == 0
#   end
#
#   test "repeated calls to add_parent do not increment child_count" do
#     parent = insert(:message)
#     child = insert(:message)
#     {:ok, child} = Message.add_parent(child, parent)
#     assert Repo.get(Message, parent.id).child_count == 1
#     Message.add_parent(child, parent)
#     Message.add_parent(child, parent)
#     Message.add_parent(child, parent)
#     assert Repo.get(Message, parent.id).child_count == 1
#   end
#
#   test "adding with parent_id in changeset works", %{room: room, user: user, parent: parent} do
#     before_count = Repo.get(Message, parent.id).child_count
#     message = Message.changeset(%Message{}, %{room_id: room.id, user_id: user.id, body: "Testing", parent_id: parent.id}) |> Repo.insert!
#     assert Repo.get(Message, parent.id).child_count == (before_count + 1)
#     assert Message.parent(message).id == parent.id
#   end
#
#   test "editing the ancestry updates count and decrements if old parent (via changeset)", %{parent: parent, child: child, other_parent: other_parent} do
#     other_parent_count = Repo.get(Message, other_parent.id).child_count
#     parent_count = Repo.get(Message, parent.id).child_count
#     assert child.ancestry == "#{parent.id}."
#     child = Message.changeset(child, %{parent_id: other_parent.id}) |> Repo.update!
#     assert Repo.get(Message, other_parent.id).child_count == other_parent_count + 1
#     assert Repo.get(Message, parent.id).child_count == parent_count - 1
#     assert child.ancestry == "#{other_parent.id}."
#   end
#
#   test "editing the ancestry updates count and decrements if old parent (via add_parent)", %{parent: parent, child: child, other_parent: other_parent} do
#     other_parent_count = Repo.get(Message, other_parent.id).child_count
#     parent_count = Repo.get(Message, parent.id).child_count
#     assert child.ancestry == "#{parent.id}."
#     child = Message.add_parent!(child, other_parent)
#     assert Repo.get(Message, other_parent.id).child_count == other_parent_count + 1
#     assert Repo.get(Message, parent.id).child_count == parent_count - 1
#     assert child.ancestry == "#{other_parent.id}."
#   end
#
#   describe "editing parent" do
#     test "creating and editing via changeset updates ancestry and child_count correctly" do
#       parent = insert(:message)
#       {:ok, child} = Message.changeset(%Message{}, %{parent_id: parent.id, user_id: parent.user.id, room_id: parent.room.id, body: "child body"})
#                     |> Repo.insert
#       assert Repo.get(Message, parent.id).child_count == 1
#       assert child.ancestry == "#{parent.id}."
#       new_parent = insert(:message)
#       {:ok, child} = Message.changeset(child, %{parent_id: new_parent.id}) |> Repo.update
#       assert Repo.get(Message, parent.id).child_count == 0
#       assert Repo.get(Message, new_parent.id).child_count == 1
#       assert child.ancestry == "#{new_parent.id}."
#     end
#
#     test "creating and editing via add_parent updates ancestry and child_count correctly" do
#       parent = insert(:message)
#       child = insert(:message)
#       Message.add_parent(child, parent)
#       assert Repo.get(Message, parent.id).child_count == 1
#       assert Repo.get(Message, child.id).ancestry == "#{parent.id}."
#       new_parent = insert(:message)
#       Message.add_parent(child, new_parent)
#       assert Repo.get(Message, parent.id).child_count == 0
#       assert Repo.get(Message, new_parent.id).child_count == 1
#       assert Repo.get(Message, child.id).ancestry == "#{new_parent.id}."
#     end
#   end
#
#   test "correct ancestry is added to parent model", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child} do
#     assert parent.ancestry == nil
#     assert child.ancestry == "#{parent.id}#{@delimiter}"
#     assert child2.ancestry == "#{parent.id}#{@delimiter}"
#     assert child_of_child.ancestry == "#{parent.id}#{@delimiter}#{child.id}#{@delimiter}"
#   end
#
#   test "correct parent is returned", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child, other_parent: other_parent, other_child: other_child} do
#     assert Message.parent(parent) == nil
#     assert Message.parent(child).id == parent.id
#     assert Message.parent(child2).id == parent.id
#     assert Message.parent(child_of_child).id == child.id
#     assert Message.parent(other_child).id == other_parent.id
#     assert Message.parent(other_parent) == nil
#   end
#
#   test "correct children are returned", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child} do
#     assert Repo.all(Message.children(parent)) |> Enum.sort == [Repo.get(Message, child.id), Repo.get(Message, child2.id)] |> Enum.sort
#      assert Repo.all(Message.children(child)) == [Repo.get(Message, child_of_child.id)]
#     assert Repo.all(Message.children(child_of_child)) == []
#   end
#
#   test "correct descendants are returned", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child} do
#     assert Repo.all(Message.descendants(parent)) |> Enum.sort == [Repo.get(Message, child.id), Repo.get(Message, child2.id), Repo.get(Message, child_of_child.id)] |> Enum.sort
#     assert Repo.all(Message.descendants(child)) == [Repo.get(Message, child_of_child.id)]
#     assert Repo.all(Message.descendants(child_of_child)) == []
#   end
#
#   test "correct root is returned", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child} do
#     assert Message.root(parent).id == parent.id
#     assert Message.root(child).id == parent.id
#     assert Message.root(child2).id == parent.id
#     assert Message.root(child_of_child).id == parent.id
#   end
#
#   test "correct siblings are returned", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child, childless: childless, other_parent: other_parent, other_child: other_child} do
#     assert Message.siblings(child) |> Repo.all |> Enum.map(&(&1.id)) |> Enum.sort == [child, child2] |> Enum.map(&(&1.id)) |> Enum.sort
#     assert Message.siblings(child_of_child) |> Repo.all |> Enum.map(&(&1.id)) |> Enum.sort == [child_of_child.id] |> Enum.sort
#     assert Message.siblings(parent) |> Repo.all |> Enum.map(&(&1.id)) |> Enum.sort == [parent.id, other_parent.id] |> Enum.sort
#     assert Message.siblings(childless) |> Repo.all |> Enum.map(&(&1.id)) |> Enum.sort == [parent.id, other_parent.id] |> Enum.sort
#     assert Message.siblings(childless, include_childless: true) |> Repo.all |> Enum.map(&(&1.id)) |> Enum.sort == [parent, childless, other_parent]  |> Enum.map(&(&1.id)) |> Enum.sort
#     assert Message.siblings(parent, include_childless: true) |> Repo.all |> Enum.map(&(&1.id)) |> Enum.sort == [parent, childless, other_parent]  |> Enum.map(&(&1.id)) |> Enum.sort
#   end
#
#   test "correct ancestors are returned", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child, childless: childless} do
#     assert Message.ancestors(child) |> Repo.all |> Enum.map(&(&1.id)) == [parent.id]
#     assert Message.ancestors(child2) |> Repo.all |> Enum.map(&(&1.id)) == [parent.id]
#     assert Message.ancestors(child_of_child) |> Repo.all |> Enum.map(&(&1.id)) == [parent.id, child.id]
#     assert Message.ancestors(childless) |> Repo.all |> Enum.map(&(&1.id)) == []
#     assert Message.ancestors(parent) |> Repo.all |> Enum.map(&(&1.id)) == []
#   end
#
#   test "ancestor_ids is correct", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child, childless: childless} do
#     assert Message.ancestor_ids(parent) == []
#     assert Message.ancestor_ids(child) == [parent.id]
#     assert Message.ancestor_ids(child2) == [parent.id]
#     assert Message.ancestor_ids(child_of_child) == [parent.id, child.id]
#   end
#
#   test "path_ids is correct", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child, childless: childless} do
#     assert Message.path_ids(parent) == [parent.id]
#     assert Message.path_ids(child) == [parent.id, child.id]
#     assert Message.path_ids(child2) == [parent.id, child2.id]
#     assert Message.path_ids(child_of_child) == [parent.id, child.id, child_of_child.id]
#   end
#
#   test "depth is correct", %{parent: parent, child: child, child2: child2, child_of_child: child_of_child, childless: childless} do
#     assert Message.depth(parent) == 0
#     assert Message.depth(child) == 1
#     assert Message.depth(child2) == 1
#     assert Message.depth(child_of_child) == 2
#   end
#
#   test "correct subtree is created", %{parent: %{id: parent_id} = parent, child: %{id: child_id} = child, child2: %{id: child2_id} = child2, child_of_child: %{id: child_of_child_id} = child_of_child, childless: childless} do
#     assert %{
#       id: ^parent_id,
#       ancestry: nil,
#       children: [
#         %{id: ^child2_id, ancestry: _, children: []},
#         %{id: ^child_id, ancestry: _, children: [
#           %{id: ^child_of_child_id, ancestry: _, children: []}
#         ]}
#       ]
#     } = Message.subtree(parent)
#
#     assert %{id: ^child_id, ancestry: _, children: [
#       %{id: ^child_of_child_id, ancestry: _, children: []}
#     ]} = Message.subtree(child)
#   end
#
# end

defmodule SyntheticManager.GroupsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SyntheticManager.Groups` context.
  """

  @doc """
  Generate a group.
  """
  def group_fixture(attrs \\ %{}) do
    {:ok, group} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> SyntheticManager.Groups.create_group()

    group
  end
end
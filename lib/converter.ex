defmodule MainConverter do
  def main(args) do
    case parse_args(args) do
      {:ok, input_file, output_file} ->
        input_file
        |> read_json_file()
        |> convert_to_csv()
        |> write_csv_file(output_file)

      :error ->
        IO.puts("Usage: json_to_csv <input_json_file> <output_csv_file>")
    end
  end

  defp parse_args([input_file, output_file]), do: {:ok, input_file, output_file}
  defp parse_args(_), do: :error

  defp read_json_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} ->
            case extract_first_array(data) do
              {:ok, array_data} -> array_data
              :error ->
                IO.puts("Error: No array found in JSON data")
                System.halt(1)
            end

          {:error, reason} ->
            IO.puts("Error parsing JSON: #{inspect(reason)}")
            System.halt(1)
        end

      {:error, reason} ->
        IO.puts("Error reading file: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp extract_first_array(data) do
    cond do
      is_list(data) ->
        {:ok, data}

      is_map(data) ->
        data
        |> Map.values()
        |> Enum.reduce_while(:error, fn value, acc ->
          case extract_first_array(value) do
            {:ok, array_data} -> {:halt, {:ok, array_data}}
            :error -> {:cont, acc}
          end
        end)

      true ->
        :error
    end
  end

  defp convert_to_csv(data) do
    flattened_values = Enum.map(data, &flatten_vals/1)
    headers = flattened_values |> Enum.flat_map(&Map.keys/1) |> Enum.uniq()
    rows = [headers] ++ Enum.map(flattened_values, fn map ->
      Enum.map(headers, fn header -> Map.get(map, header, "") end)
    end)
    rows
  end

  defp flatten_vals(map, parent_key \\ "", acc \\ %{}) do
    Enum.reduce(map, acc, fn {key, value}, acc ->
      new_key = if parent_key == "", do: "#{key}", else: "#{parent_key}.#{key}"
      cond do
        is_map(value) ->
          flatten_vals(value, new_key, acc)

        is_list(value) ->
          Map.put(acc, new_key, Enum.join(value, "; "))

        true ->
          Map.put(acc, new_key, value)
      end
    end)
  end

  defp write_csv_file(rows, output_file) do
    output_file
    |> File.open([:write], fn file ->
      rows
      |> CSV.encode()
      |> Enum.each(&IO.write(file, &1))
    end)

    IO.puts("CSV file written to #{output_file}")
  end
end


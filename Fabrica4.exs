defmodule Fabrica do

  def main do
    IO.puts("Para empezar a fabricar un nuevo robot ingrese: \n
    - 'a' para un robot que toma 15s\n
    - 'b' para un robot que toma 20s\n
    - 'c' para un robot que toma 25s\n
    - 'x' para terminar")

    vigilante_pid = spawn(Fabrica, :vigilante, [[] , []])

    solicitar(vigilante_pid)
  end


  def solicitar(vigilante_pid) do
    entrada = IO.gets("\n") |> String.trim()

    cond do
      entrada == "x" ->
        IO.puts("Finalizado.")
        :ok

      String.contains?("abc", String.downcase(entrada)) and String.length(entrada) == 1 ->

        send(vigilante_pid, {:nueva_tarea, String.downcase(entrada)})
        solicitar(vigilante_pid)

      true ->
        IO.puts("Entrada no válida.")
        solicitar(vigilante_pid)
    end
  end

  def cronometro(entrada, vigilante_pid) do
    segundos =
      case entrada do
        "a" -> 15
        "b" -> 20
        "c" -> 25
      end


    IO.puts("Creando robot tipo #{entrada}, tomara #{segundos} segundos")
    :timer.sleep(segundos * 1000)
    IO.puts("\nRobot tipo #{entrada} terminado")
    send(vigilante_pid, {:terminado, self()})
  end

  def vigilante(actuales, pendientes) do

    IO.puts("Robots en construcción: #{length(actuales)}/7")
    IO.puts("Pendientes: #{inspect(pendientes)}")


    receive do
      {:nueva_tarea, entrada} ->
        if length(actuales) < 7 do
          tarea = spawn(Fabrica, :cronometro, [entrada, self()])
          vigilante([tarea | actuales], pendientes)
        else
          IO.puts("No hay capacidad, añadiendo '#{entrada}' a pendienste")
          vigilante(actuales, pendientes ++ [entrada])
        end

      {:terminado, tarea_pid} ->
        actuales = List.delete(actuales, tarea_pid)

        {actuales, pendientes} =
          if pendientes != [] and length(actuales) < 7 do
            [siguiente | resto] = pendientes
            tarea = spawn(Fabrica, :cronometro, [siguiente, self()])
            {[tarea | actuales], resto}
          else
            {actuales, pendientes}
          end

        vigilante(actuales, pendientes)
    end
  end

end

Fabrica.main()

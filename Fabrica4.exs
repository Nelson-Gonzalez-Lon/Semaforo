defmodule Fabrica do
  # Punto de entrada
  def main do
    IO.puts("Para empezar a fabricar un nuevo robot ingrese: \n
    - 'a' para un robot que toma 15s\n
    - 'b' para un robot que toma 20s\n
    - 'c' para un robot que toma 15s\n
    - 'x' para terminar")

    # Creamos el proceso vigilante independiente
    vigilante_pid = spawn(Fabrica, :vigilante, [[] , []])

    # Iniciamos las solicitudes, pasando el PID del vigilante
    solicitar(vigilante_pid)
  end


  def solicitar(vigilante_pid) do
    entrada = IO.gets("\n") |> String.trim()

    cond do
      entrada == "x" ->
        IO.puts("Finalizado.")
        :ok

      String.contains?("abc", entrada) ->
        # Enviamos la tarea al vigilante
        send(vigilante_pid, {:nueva_tarea, String.downcase(entrada)})
        solicitar(vigilante_pid)

      true ->
        IO.puts("Entrada no válida.")
        solicitar(vigilante_pid)
    end
  end

  # Crea un timer dependiendo del robot, al terminar avisara al vijilante
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

  # Vigilante mantiene tareas activas y pendientes
  def vigilante(actuales, pendientes) do
    # Mostramos estado
    IO.puts("Robots en construcción: #{length(actuales)}/7")
    IO.puts("Pendientes: #{inspect(pendientes)}")

    #Vigilante esta siempre atento a quien le envia mensage
    receive do
      #Este es un mensaje que llega desde solicitar, si hay espacio inicia la tarea del nuevo robot
      #Si no, lo añada a la lista de espera
      {:nueva_tarea, entrada} ->
        if length(actuales) < 7 do
          tarea = spawn(Fabrica, :cronometro, [entrada, self()])
          vigilante([tarea | actuales], pendientes)
        else
          IO.puts("No hay capacidad, añadiendo '#{entrada}' a pendienste")
          vigilante(actuales, pendientes ++ [entrada])
        end

      # Notificación de cronómetro terminado
      {:terminado, tarea_pid} ->
        actuales = List.delete(actuales, tarea_pid)

        # Si hay pendientes, lanzamos el siguiente
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

  # Valida si es un número entero
  def es_entero?(str) do
    case Integer.parse(str) do
      :error -> false
      {_num, ""} -> true
      _ -> false
    end
  end
end

Fabrica.main()

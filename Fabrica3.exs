defmodule Fabrica do
  # Punto de entrada
  def main do
    IO.puts("Para empezar un nuevo contador ingrese un número, para terminar ingrese 'x'")

    # Creamos el proceso vigilante independiente
    vigilante_pid = spawn(Fabrica, :vigilante, [[] , []])

    # Iniciamos la UI, pasando el PID del vigilante
    ui(vigilante_pid)
  end

  # UI principal
  def ui(vigilante_pid) do
    entrada = IO.gets("> ") |> String.trim()

    cond do
      entrada == "x" ->
        IO.puts("Finalizado.")
        :ok

      es_entero?(entrada) ->
        segundos = String.to_integer(entrada)
        # Enviamos la tarea al vigilante
        send(vigilante_pid, {:nueva_tarea, segundos})
        ui(vigilante_pid)

      true ->
        IO.puts("Entrada no válida.")
        ui(vigilante_pid)
    end
  end

  # Cronómetro: notifica al vigilante al terminar
  def cronometro(segundos, vigilante_pid) do
    IO.puts("Iniciando cronómetro de #{segundos}s...")
    :timer.sleep(segundos * 1000)
    IO.puts("Cronómetro de #{segundos}s terminado")
    send(vigilante_pid, {:terminado, self()})
  end

  # Vigilante: mantiene tareas activas y pendientes
  def vigilante(actuales, pendientes) do
    # Mostramos estado
    IO.puts("Cronómetros activos: #{length(actuales)}/4")
    IO.puts("Pendientes: #{inspect(pendientes)}")

    receive do
      # Nueva tarea enviada desde UI
      {:nueva_tarea, segundos} ->
        if length(actuales) < 4 do
          tarea = spawn(Fabrica, :cronometro, [segundos, self()])
          vigilante([tarea | actuales], pendientes)
        else
          IO.puts("No hay capacidad, añadiendo #{segundos} a pendienste")
          vigilante(actuales, pendientes ++ [segundos])
        end

      # Notificación de cronómetro terminado
      {:terminado, tarea_pid} ->
        actuales = List.delete(actuales, tarea_pid)

        # Si hay pendientes, lanzamos el siguiente
        {actuales, pendientes} =
          if pendientes != [] and length(actuales) < 4 do
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

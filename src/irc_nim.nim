import strutils
import net
import os

type 
  IRClient = ref object of RootObj
    connection: Socket
    username*: string
    server: string
    port: Port
    channel: string

proc initIRClient(name: string, chan: string): IRClient =
  var server = "chat.freenode.net"
  var port = Port(6667)
  var initialSocket = newSocket()
  initialSocket.connect(server, port)
  IRClient(connection: initialSocket, username: name, server: server, port: port, channel: chan)

proc getResponse(obj: IRClient): string =
  obj.connection.recv(1024)

proc sendCommand(obj: IRClient, command: string, message: string): void =
  obj.connection.send(command & " " & message & "\r\n")

proc joinChannel(obj: IRClient): void =
  obj.sendCommand("JOIN", obj.channel)

proc formatResponse(response: string): void =
  if not isEmptyOrWhitespace(response):
    var message = response.strip().split(":")
    echo("\n< " & message[1].split("!")[0] & "> " & message[2].strip())

when isMainModule:
  if paramCount() != 2:
    echo("Uso: ./irc_nim USUARIO CANAL\n")
    echo("nv bro.\n")
    quit(0)

  var username = paramStr(1)
  var channel = "#" & paramStr(2)
  var joined = false
  var client = initIRClient(username, channel)
  while(joined == false):
    client.sendCommand("NICK", username)
    client.sendCommand("USER", username & " * * :" & username)
    var response = client.getResponse()
    formatResponse(response)

    # por alguna razon no funciono el login? probamos de vuelta
    if "No Ident response" in response:
      echo("tuve que logearme de vuelta\n")
      client.sendCommand("NICK", username)
      client.sendCommand("USER", username & " * * :" & username)

    # ponele que nos aceptaron
    if "376" in response:
      echo("nos aceptaron\n")
      client.joinChannel()

    # ya estan usando el nombre de usuario? bueno intentemo con guioncito
    if "433" in response:
      echo("probemos otro nombre\n")
      client.sendCommand("NICK", "_" & username)
      client.sendCommand("USER", username & " * * :" & username)

    # PING? PONG.
    if "PING" in response:
      echo("PONG!\n")
      client.sendCommand("PONG :", response.split(":")[1])

    # estamo pa la party
    if "366" in response:
      echo("Entramoh\n")
      joined = true

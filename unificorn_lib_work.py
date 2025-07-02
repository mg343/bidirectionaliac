from unificontrol import UnifiClient

# Set up UnifiClient connection
unifi_client = UnifiClient()

# Login to the controller
unifi_client.login()

# Fetch the list of connected clients (devices)
clients = unifi_client.list_clients()

# Print details of all connected devices
for client in clients:
    print(f"MAC Address: {client['mac']}")
    print(f"IP Address: {client['ip']}")
    print(f"Device Name: {client.get('hostname', 'Unknown')}")
    print(f"Connection Type: {client['type']}")
    print("-" * 40)

# Logout after you're done
unifi_client.logout()
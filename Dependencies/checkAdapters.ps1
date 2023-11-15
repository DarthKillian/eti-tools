# Get all physiscal adpaters
# Now iterate through them and only get the adapters that are up then assign them to the adapter select box

function checkAdapters () {
   # Clear the listbox to make sure nothing funky exists before enumerating our items
   $selectAdapter.Items.Clear()
   foreach ($adapter in get-wmiobject win32_networkadapter -filter "netconnectionstatus = 2" | Select-Object netconnectionid) {
        $adapter | ForEach-Object { $selectAdapter.Items.Add($_.netconnectionid) } | Out-Null
   }

   # Select the first adapter in the list and focus it
   $selectAdapter.SelectedIndex = 0
   $selectAdapter.Focus() | Out-Null
}
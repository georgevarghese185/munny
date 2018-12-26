<template>

  <div class="home-screen">
    <NavBar :app="app" :title="app.name"/>
    <!-- <SelectorDialog label="Choose a Service..." :visible="dialogVisible" :options="services"/> -->
		<!-- <SelectorDialog title="Choose a plugin for viewing account details" label="Choose a Viewer..." :visible="dialogVisible" :options="viewers"/> -->
		<!-- <InputsDialog :visible="dialogVisible" serviceName="HDFC Bank"/> -->
		<!-- <EncryptDataDialog :visible="dialogVisible" :encryptOptions="encryptOptions"/> -->
		<!-- <PasswordDialog title="Enter a PIN" :visible="dialogVisible" :isNumberPin="true"/> -->
		<!-- <SimpleDialog :visible="dialogVisible" message="Please authenticate the next screen"/> -->
		<!-- <SimpleDialog :visible="dialogVisible" message="Account added"/> -->
		<!-- <SyncDialog :visible="dialogVisible" :app="app" :accounts="accounts"/> -->
    <Accounts :app="app" :accounts="accounts"/>
    <div class="bottom-buttons-container">
      <Button class="bottom-button" label="Sync" @click="$emit('sync')"/>
      <Button class="bottom-button" label="View Details" @click="$emit('viewDetails')"/>
    </div>
  </div>

</template>




<script>
  import Button from './widgets/Button.vue'
  import NavBar from './widgets/nav/NavBar.vue'
  import Accounts from './widgets/accounts/Accounts.vue'
  import SelectorDialog from './widgets/dialogs/SelectorDialog.vue'
	import InputsDialog from './widgets/dialogs/InputsDialog.vue'
	import EncryptDataDialog from './widgets/dialogs/EncryptDataDialog.vue'
	import PasswordDialog from './widgets/dialogs/PasswordDialog.vue'
	import SimpleDialog from './widgets/dialogs/SimpleDialog.vue'
	import SyncDialog from './widgets/dialogs/SyncDialog.vue'

  export default {
    props: ["app", "accounts", "services", "encryptOptions", "viewers"],
    components: {
      Button, NavBar, Accounts, SelectorDialog, InputsDialog, EncryptDataDialog,
			PasswordDialog, SimpleDialog, SyncDialog
    }
  }

</script>




<style scoped>

  .home-screen {
    position: absolute;
    width: 100%;
    height: 100%;
    background: #fbfbfb;
  }

  .bottom-buttons-container {
    position: fixed;
    bottom: 12px;
    left: 0;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .bottom-button {
    margin: 0 8px;
  }

</style>

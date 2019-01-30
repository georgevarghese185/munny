<template>

  <div class="home-screen">
    <NavBar :app="app" :title="app.name"/>
		<SelectorDialog v-if="dialogs.selectorDialog.visible" :visible="dialogs.selectorDialog" :title="dialogs.selectorDialog.title"
      :label="dialogs.selectorDialog.label" :options="dialogs.selectorDialog.options" @done="onSelectorDialogDone"/>
		<InputsDialog :visible="dialogs.inputsDialog.visible" :serviceName="dialogs.inputsDialog.serviceName" @ready="onInputsDialogReady"/>
		<EncryptDataDialog :visible="dialogs.encryptDialog.visible" :encryptOptions="dialogs.encryptDialog.options" @done="onEncryptionSelect"/>
		<PasswordDialog :title="dialogs.passwordDialog.title" :visible="dialogs.passwordDialog.visible" :inputType="dialogs.passwordDialog.inputType" @done="onInput"/>
		<SimpleDialog :visible="dialogs.simpleDialog.visible" :message="dialogs.simpleDialog.message" @done="onOkClick"/>
		<SyncDialog :visible="dialogs.syncDialog.visible" :app="app" :accounts="dialogs.syncDialog.accounts"/>
    <Accounts :app="app" :accounts="accounts" @addAccount="onAddAccount"/>
    <div class="bottom-buttons-container">
      <Button class="bottom-button" :disabled="accounts.length == 0" label="Sync" @click="onSyncClick"/>
      <Button class="bottom-button" :disabled="accounts.length == 0" label="View Details" @click="onViewDetailsClick"/>
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
  import { updateVue } from 'src/common/ui/util.js'

  export default {
    props: ["initialState", "onEvent", "setStateListener"],
    data: function() {
      let { app, accounts, encryptOptions, viewers, dialogs } = this.initialState;
      return {
        app,
        accounts,
        encryptOptions,
        viewers,
        dialogs
      }
    },
    mounted: function() {
      let vm = this;
      this.setStateListener(function(newState) {
        updateVue(vm, newState);
      });
    },
    methods: {
      onSelectorDialogDone: function(selection) {
        this.onEvent('SelectorDialog', selection)
      },
      onAddAccount: function() {
        this.onEvent('AddAccountClick');
      },
      onSyncClick: function() {
        this.onEvent('SyncClick')
      },
      onViewDetailsClick: function() {
        this.onEvent('ViewDetailsClick')
      },
      onInputsDialogReady: function(id) {
        this.onEvent('InputsDialogRendered', id)
      },
      onEncryptionSelect: function(choice) {
        this.onEvent('EncryptOption', choice);
      },
      onOkClick: function() {
        this.onEvent('OkClick');
      },
      onInput: function(password) {
        this.onEvent('PasswordEnter', password);
      }
    },
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

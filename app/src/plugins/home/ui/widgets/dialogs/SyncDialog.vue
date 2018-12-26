<template>

	<Dialog :visible="visible">
    <template slot="title">
      Syncing your accounts
    </template>
    <div class="dialog-contents">
			<InputsDialog :visible="inputsDialogVisible" zIndex="45"/>
			<Dialog :visible="cancelDialogVisible" zIndex="45">
				<template slot="title">
					Are you sure you want to cancel account sync?
				</template>
				<div class="cancel-dialog-contents">
					<Button class="cancel-dialog-button" label="No" @click="cancelDialogVisible = false"/>
					<Button class="cancel-dialog-button" label="Yes" @click="$emit('cancel')" />
				</div>
			</Dialog>
      <div class="account" v-for="account in accounts" :key="account.name">
        <div class="account-left-side">
          <div class="account-logo-name">
            <img class="account-logo" :src="`${app.pluginDir}/assets/${account.logo}`"/>
            <p class="account-name"> {{account.name}} </p>
          </div>
          <p :class="{'account-sync-status':true, 'input-status':account.sync.status === INPUT_REQUIRED}">
						{{account.sync.message}}
					</p>
        </div>
        <div class="loader">
						<img class="sync-status-icon" v-if="account.sync.status === SUCCESS" :src="`${app.pluginDir}/assets/tick.png`"/>
						<img class="sync-status-icon" v-else-if="account.sync.status === FAILED" :src="`${app.pluginDir}/assets/cross.png`"/>
						<img class="sync-status-icon" v-else-if="account.sync.status === INPUT_REQUIRED" :src="`${app.pluginDir}/assets/exclamation.png`"/>
					<DotLoader v-else/>
        </div>
      </div>
			<Button v-if="syncComplete" label="OK" @click="$emit('done')" />
      <Button v-else label="Cancel" @click="cancelDialogVisible = true"/>
    </div>
  </Dialog>

</template>




<script>
  import Dialog from './Dialog.vue'
	import InputsDialog from './InputsDialog.vue'
  import Button from '../Button.vue'
  import DotLoader from '../DotLoader.vue'

	export default {
    props: ["app", "visible", "accounts"],
		data: function() {
			return {
				SUCCESS: "success",
				FAILED: "failed",
				INPUT_REQUIRED: "input_required",
				SYNCING: "syncing",
				inputsDialogVisible: false,
				cancelDialogVisible: false
			}
		},
    computed: {
      syncComplete: function() {
        for(let i = 0; i < this.accounts.length; i++) {
					let status = this.accounts[i].sync.status;
          if(status !== this.SUCCESS && status !== this.FAILED) {
            return false;
          }
        }
        return true;
      }
    },
    components: { Dialog, Button, DotLoader, InputsDialog }
  }

</script>




<style scoped>

  .dialog-contents {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 12px 12px;
  }

  .account {
    display: flex;
    width: 100%;
    flex-direction: row;
    margin: 18px 0 18px 0;
  }

  .account-left-side {
    display: flex;
    flex-direction: column;
    flex-grow: 1;
    align-items: flex-start;
  }

  .account-logo-name {
    display: flex;
    flex-direction: row;
    align-items: center;
    width: 100%;
  }

  .account-logo {
    width: 24px;
    height: 24px;
    flex-grow: 0;
  }

  .account-name {
    color: #000000;
    font-size: 16px;
    flex-grow: 1;
    margin: 0 0 0 14px;
  }

  .account-sync-status {
    color: #959595;
    font-size: 12px;
    margin: 8px 0 0 28px;
  }

	.input-status {
		color: #e8a625;
	}

  .loader {
    width: 32px;
    flex-grow: 0;
    display: flex;
    align-items: center;
  }

	.sync-status-icon {
		width: 22px;
		height: 22px;
	}

	.cancel-dialog-contents {
		display: flex;
		flex-direction: row;
		align-items: center;
		justify-content: center;
	}

	.cancel-dialog-button {
		width: 123px;
		height: 40px;
		margin: 27px 6;
	}

</style>

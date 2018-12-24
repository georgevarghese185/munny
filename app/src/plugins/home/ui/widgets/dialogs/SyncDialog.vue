<template>

	<Dialog :visible="visible">
    <template slot="title">
      Syncing your accounts
    </template>
    <div class="dialog-contents">
      <div class="account" v-for="account in accounts" :key="account.name">
        <div class="account-left-side">
          <div class="account-logo-name">
            <img class="account-logo" :src="`${app.pluginDir}/assets/${account.logo}`"/>
            <p class="account-name"> {{account.name}} </p>
          </div>
          <p class="account-sync-status"> {{account.syncStatus}} </p>
        </div>
        <div class="loader">
          <DotLoader/>
        </div>
      </div>
      <Button v-if="!syncComplete" label="Cancel" @click="this.$emit('cancel')"/>
      <Button v-if="syncComplete" label="OK" @click="this.$emit('done')" />
    </div>
  </Dialog>

</template>




<script>
  import Dialog from './Dialog.vue'
  import Button from '../Button.vue'
  import DotLoader from '../DotLoader.vue'

	export default {
    props: ["app", "visible", "accounts"],
    computed: {
      syncComplete: function() {
        for(let i = 0; i < this.accounts.length; i++) {
          if(!this.accounts[i].syncComplete) {
            return false;
          }
        }
        return true;
      }
    },
    components: { Dialog, Button, DotLoader }
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

  .loader {
    width: 32px;
    flex-grow: 0;
    display: flex;
    align-items: center;
  }

</style>

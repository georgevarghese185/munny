<template>

	<div class="accounts-card">
    <p class="title light-text"> Accounts </p>
    <p v-if="!accounts.length" class="no-accounts"> No accounts added </p>
    <Account :app="app" v-for="account in accounts" :account="account"/>
    <div class="add-account">
      <img class="add-icon" :src="`${app.pluginDir}/assets/add.png`"/>
      <p class="add-label light-text"> Add Account </p>
    </div>
	</div>

</template>




<script>
	import Account from './Account.vue'

	export default {
    props: ["app", "accounts"],
		components: {
			Account
		}
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
  }

	.accounts-card {
    padding: 32px 12px 18px 32px;
    background-color: #ffffff;
    margin: 0;
    border-bottom: #cecece88 solid 1px;
  }

  .title {
    margin: 0;
    font-size: 14px;
    margin-bottom: 18px;
  }

  .no-accounts {
    font-size: 12px;
    text-align: center;
    margin: 28px 22px 0 0;
    color: #b0b0b0;
  }

  .add-account {
    display: flex;
    align-items: center;
    margin-top: 38px;
  }

  .add-icon {
    width: 24px;
    height: 24px;
  }

  .add-label {
    font-size: 14px;
    margin: 0;
    margin-left: 16px;
    display: inline-block;
  }

  .light-text {
    color: #a1a1a1;
  }

</style>

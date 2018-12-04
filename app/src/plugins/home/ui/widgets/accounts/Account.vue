<template>

  <div class="account clickable">
    <img class="account-logo" :src="`${app.pluginDir}/assets/${account.logo}`"/>
    <p class="account-name"> {{account.name}} </p>
    <p class="last-updated light-text"> {{account.lastUpdated}} </p>
  </div>

</template>




<script>

	export default {
    props: ["app", "account"]
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
  }

  .account {
    padding-left: 8px;
    display: flex;
    align-items: center;
    margin-bottom: 18px;
    background-color: #ffffff;
  }

  .account:active {
    background-color: #c9c9c9;
  }

  .account-logo {
    width: 26px;
    height: 26px;
    flex-grow: 0;
    margin-right: 16px;
  }

  .account-name {
    color: #444444;
    font-size: 16px;
    flex-grow: 0;
  }

  .last-updated {
    font-size: 12px;
    text-align: right;
    padding-bottom: 4px;
    flex-grow: 1;
  }

  .light-text {
    color: #a1a1a1;
  }

  .clickable {
    transition: background-color 0.1s;
  }

</style>

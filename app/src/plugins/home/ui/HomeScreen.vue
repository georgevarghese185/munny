<template>

  <div class="home-screen">
    <NavBar :app="app" :title="app.name"/>
    <Accounts :app="app" :accounts="accounts"/>
  </div>

</template>




<script>
  import NavBar from './widgets/nav/NavBar.vue'
  import Accounts from './widgets/accounts/Accounts.vue'

  export default {
    props: ["app", "accounts"],
    components: {
      NavBar,
      Accounts
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

</style>

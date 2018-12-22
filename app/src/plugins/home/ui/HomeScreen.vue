<template>

  <div class="home-screen">
    <NavBar :app="app" :title="app.name"/>
    <Accounts :app="app" :accounts="accounts" :services="services" :encryptOptions="encryptOptions"/>
  </div>

</template>




<script>
  import NavBar from './widgets/nav/NavBar.vue'
  import Accounts from './widgets/accounts/Accounts.vue'

  export default {
    props: ["app", "accounts", "services", "encryptOptions"],
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

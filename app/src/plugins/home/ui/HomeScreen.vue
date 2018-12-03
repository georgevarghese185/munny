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
    data: function(){
      return {
        app: {
          name: "Munny",
          pluginDir: "home"
        },
        accounts: [
          {
            name: "ICICI",
            logo: "bank_logos/icici.png",
            lastUpdated: "4 hours ago"
          },
          {
            name: "HDFC",
            logo: "bank_logos/hdfc.png",
            lastUpdated: "4 hours ago"
          }
        ]
      }
    },
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

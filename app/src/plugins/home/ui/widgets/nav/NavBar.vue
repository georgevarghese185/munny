<template>

  <div class="nav-bar">
    <Overlay zIndex="50" :visible="navDrawerOpen" @click.native="navDrawerOpen = !navDrawerOpen"/>
    <NavDrawer :open="navDrawerOpen" zIndex="51"/>
    <div class="nav-button clickable" @click="navButtonClick">
      <img class="nav-bar-icon" :src="`${app.pluginDir}/assets/nav.png`"/>
    </div>
    <p class="title"> {{title}} </p>
  </div>

</template>




<script>
  import Overlay from '../Overlay.vue'
  import NavDrawer from './NavDrawer.vue'

  export default {
    props: ["app", "title"],
    data: function() {
      return {
        navDrawerOpen: false
      }
    },
    methods: {
      navButtonClick: function() {
        setTimeout(() =>
          this.navDrawerOpen = !this.navDrawerOpen
          ,100
        )
      }
    },
    components: {
      Overlay,
      NavDrawer
    }
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
  }

  .nav-bar {
    position: relative;
    background-color: #333333;
    border-bottom: #cecece88 solid 1px;
  }

  .title {
    position: absolute;
    left: 0;
    top: 0;
    margin: 0;
    display: inline-block;
    width: 100%;
    height: 52px;
    line-height: 52px;
    color: #f5f5f5;
    font-size: 22px;
    text-align: center;
    pointer-events: none;
  }

  .nav-button {
    width: 56px;
    height: 52px;
    background-color: #333333;
  }

  .nav-button:active {
    background-color: #5d5d5d;
  }

  .nav-bar-icon {
    position: absolute;
    display: inline-block;
    width: 35px;
    height: 26px;
    margin: 14px 12px;
  }

  .clickable {
    transition: background-color 0.1s;
  }

</style>

<template>

  <div class="nav-bar">
    <div class="nav-button">
      <img class="nav-bar-icon" :src="`${app.pluginDir}/assets/nav.png`"/>
    </div>
    <p class="title"> {{title}} </p>
  </div>

</template>




<script>

  export default {
    props: ["app", "title"]
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
  }

  .nav-bar {
    position: relative;
    background-color: #333333;
    border-bottom: #cecece solid 2px;
  }

  .title {
    position: absolute;
    left: 0;
    top: 0;
    margin: 0;
    display: inline-block;
    width: 100%;
    height: 48px;
    line-height: 48px;
    color: #f5f5f5;
    font-size: 22px;
    text-align: center;
  }

  .nav-button {
    width: 56px;
    height: 48px;
  }

  .nav-bar-icon {
    position: absolute;
    display: inline-block;
    width: 35px;
    height: 28px;
    margin: 10px 10px;
  }

</style>

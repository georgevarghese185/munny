<template>

  <div class="nav-drawer-container">
    <transition name="slide">
      <div v-if="open" class="nav-drawer" :style="`z-index:${zIndex}`"/>
    </transition>
  </div>

</template>




<script>

	export default {
    props: ["zIndex", "open"]
  }

</script>




<style scoped>

	.nav-drawer {
    position: fixed;
    top: 0;
    left: 0;
    height: 100%;
    width: 280px;
    background-color: #ffffff;
  }

  .slide-enter, .slide-leave-to {
    transform: translateX(-100%);
  }

  .slide-enter-active, .slide-leave-active {
    transition: transform 0.3s
  }

</style>

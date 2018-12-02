<template>

  <div class="nav-drawer-container">
    <transition name="slide">
      <div v-if="open" class="nav-drawer" :style="`z-index:${zIndex}`">
        <p class="placeholder"> (idk lol) </p>
      </div>
    </transition>
  </div>

</template>




<script>

	export default {
    props: ["zIndex", "open"]
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
  }

	.nav-drawer {
    position: fixed;
    top: 0;
    left: 0;
    height: 100%;
    width: 280px;
    background-color: #ffffff;
  }

  .placeholder {
    height: 100%;
    top: 0;
    left: 0;
    text-align: center;
    color: #7d7d7d;
  }

  .slide-enter, .slide-leave-to {
    transform: translateX(-100%);
  }

  .slide-enter-active, .slide-leave-active {
    transition: transform 0.3s
  }

</style>

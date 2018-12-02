<template>

	<div class="overlay-container">
    <transition name="fade">
      <div v-if="visible" class="overlay" :style="`z-index:${zIndex};`"/>
    </transition>
	</div>

</template>




<script>

	export default {
    props: ["zIndex", "visible"]
  }

</script>




<style scoped>

  .overlay {
    position: fixed;
    width: 100%;
    height: 100%;
    left: 0;
    top: 0;
    background-color: #00000088;
  }

  .fade-enter, .fade-leave-to {
    opacity: 0;
  }

  .fade-enter-active, .fade-leave-active {
    transition: opacity 0.3s;
  }

</style>

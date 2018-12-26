<template>

	<div class="dot-loader">
    <div class="dot"/>
    <div class="dot" style="animation-delay: 0.33s"/>
    <div class="dot" style="animation-delay: 0.66s"/>
	</div>

</template>




<script>

	export default {
  }

</script>




<style scoped>

  .dot-loader {
    display: flex;
    align-items: center;
    justify-content: center;
    padding-left: 2px
  }

  .dot {
    background-color: #ffffff;
    border: solid 1px #707070;
    width: 4px;
    height: 4px;
    border-radius: 10px;
    margin-right: 2px;
    animation-name: colorfade;
    animation-duration: 1s;
    animation-iteration-count: infinite;
  }

  @keyframes colorfade {
    0% { background-color: #ffffff; }
    25% { background-color: #707070; }
    50% { background-color: #ffffff; }
    100% { background-color: #ffffff; }
  }

</style>

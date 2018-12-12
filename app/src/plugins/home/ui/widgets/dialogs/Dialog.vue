<template>

	<div>
    <Overlay zIndex="40" :visible="visible"/>
    <div v-if="visible" class="dialog-container">
      <div class="dialog">
        <p class="title">
          <slot name="title"></slot>
        </p>
        <slot></slot>
      </div>
    </div>
	</div>

</template>




<script>
  import Overlay from '../Overlay.vue'

	export default {
    props: ["visible"],
    components: {
      Overlay
    }
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
  }

  .dialog-container {
    display: flex;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    justify-content: center;
    align-items: center;
    z-index: 41;
  }

  .dialog {
    width: 80%;
		max-height: 70%;
    background-color: #ffffff;
		overflow: auto;
  }

  .title {
    font-size: 18px;
    text-align: center;
    margin: 14px 8px;
  }

</style>

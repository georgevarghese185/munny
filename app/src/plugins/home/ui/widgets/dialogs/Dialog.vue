<template>

	<div>
    <Overlay :zIndex="zIndex || 40" :visible="visible"/>
    <div v-if="visible" class="dialog-container" :style="`z-index:${zIndex ? zIndex+1 : 41};`">
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
    props: ["visible", "zIndex"],
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
		color: #676767
  }

</style>

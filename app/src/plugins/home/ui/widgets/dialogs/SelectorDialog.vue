<template>

	<Dialog :visible="visible">
		<template slot="title">
			{{title}}
		</template>
    <div class="dialog-contents">
      <Selector :label="label" :options="options" @select="onSelect"/>
      <Button label="OK" :disabled="selection == null" @click="onOK"/>
    </div>
  </Dialog>

</template>




<script>
  import Dialog from './Dialog.vue'
  import Selector from '../Selector.vue'
  import Button from '../Button.vue'

	export default {
    props: ["visible", "title", "label", "options"],
    data: function() {
      return {
        selection: null
      }
    },
    components: {
      Dialog,
      Selector,
      Button
    },
    methods: {
      onSelect: function(selection) {
        this.selection = selection;
      },
      onOK: function() {
        if(this.selection != null) {
          this.$emit("done", this.selection)
        }
      }
    }
  }

</script>




<style scoped>

  .dialog-contents {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-top: 24px;
    padding: 12px 12px;
  }

</style>

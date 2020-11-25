import { Pie, Bar } from 'vue-chartjs'

export const PieChart = {
  extends: Pie,
  props: ['data', 'label'],
  mounted () {
    let renderOptions = {labels: []};
    renderOptions.datasets = [{ label: this.label, backgroundColor: [], data: []}];
    this.data.forEach(data => {
        renderOptions.labels.push(data.label)
        renderOptions.datasets[0].backgroundColor.push(data.color),
        renderOptions.datasets[0].data.push(data.value)
    })
    this.renderChart(renderOptions)
  }
}

export const BarChart = {
    extends: Bar,
    props: ['data', 'label', 'color'],
    mounted () {
      const bgColor = this.color ? [] : null
      let renderOptions = {labels: []};
      renderOptions.datasets = [{ label: this.label, backgroundColor: bgColor, data: []}];
      this.data.forEach(data => {
          renderOptions.labels.push(data.label)
          if(this.color) 
            renderOptions.datasets[0].backgroundColor = this.color
          else
            renderOptions.datasets[0].backgroundColor.push(data.color)
          renderOptions.datasets[0].data.push(data.value)
      })
      console.log(Object.assign({},renderOptions))

      this.renderChart(renderOptions)
    }
  }

/* example data
{
    label: 'Special Kills',
    data: [
        {
            label: "Boomer",
            color: "#F47A1F",
            value: 20
        }
    ]
}

*/
import { Pie, Bar, mixins } from 'vue-chartjs'

export const PieChart = {
  extends: Pie,
  mixins: [mixins.reactiveProp],
  props: ['chartData'],
  mounted () {
    this.renderChart(this.chartData)
  }
}

export const BarChart = {
  extends: Bar,
  mixins: [mixins.reactiveProp],
  props: ['chartData'],
  mounted () {
    this.renderChart(this.chartData)
  }
}

export function getChartData(label, options, color) {
  const bgColor = color ? null : []
  let renderOptions = {labels: []};
  renderOptions.datasets = [{ label: label, backgroundColor: bgColor, data: []}];
  if(color) renderOptions.datasets[0].backgroundColor = color
  options.forEach(data => {
      renderOptions.labels.push(data.label)
      if(!color)
        renderOptions.datasets[0].backgroundColor.push(data.color)
      renderOptions.datasets[0].data.push(data.value)
  })
  return renderOptions;
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
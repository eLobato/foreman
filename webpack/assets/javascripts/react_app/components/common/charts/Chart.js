import c3 from 'c3';
import PropTypes from 'prop-types';
import React from 'react';
import Cable from 'actioncable'
import MessageBox from '../MessageBox';

class Chart extends React.Component {
  hasData() {
    const { config } = this.props;

    return config && config.data && config.data.columns && config.data.columns.length;
  }

  drawChart() {
    const { config } = this.props;
    if (this.hasData()) {
      this.chart = c3.generate(config);

      if (this.props.setTitle) {
        this.props.setTitle(config);
      }
    } else {
      this.chart = undefined;
    }
  }

  componentDidMount() {
    this.drawChart();
  }

  componentDidUpdate() {
    this.drawChart();
  }

  componentWillUnmount() {
    if (this.chart) {
      this.chart = this.chart.destroy();
    }
  }

  componentWillMount() {
    this.createSocket();
  }

  createSocket() {
    let cable = Cable.createConsumer('wss://centos7-devel.lobatolan.home/cable');
    this.chats = cable.subscriptions.create('JobInvocationChannel', {
      connected: () => {
        console.log("Connected to JobInvocationChannel");
      },
      received: (data) => {
        console.log(data);
      },
    });
  }

  render() {
    const msg = this.props.noDataMsg || 'No data available';

    return this.hasData() ? (
      <div className={this.props.className} data-id={this.props.config.id} />
    ) : (
      <MessageBox msg={msg} icontype="info" />
    );
  }
}

Chart.propTypes = {
  config: PropTypes.object.isRequired,
  noDataMsg: PropTypes.string,
  setTitle: PropTypes.func,
};

export default Chart;

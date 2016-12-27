import React from 'react';
import Icon from '../common/Icon';
import moment from 'moment';

const Notification = ({created_at, seen, text, level}) => {
  const created = moment(created_at);
  const markup = seen ?
    (<span className="drawer-pf-notification-message">{text}</span>) :
    (<strong className="drawer-pf-notification-message">{text}</strong>);

  return (
    <div className="drawer-pf-notification">
      <Icon type={level} css="pull-left"></Icon>
      {markup}
      <div className="drawer-pf-notification-info">
        <span className="date">{created.format('M/D/YY')}</span>
        <span className="time">{created.format('hh:mm:ss A')}</span>
      </div>
    </div>
  );
};

export default Notification;

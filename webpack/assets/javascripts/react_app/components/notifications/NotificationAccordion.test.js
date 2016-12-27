jest.unmock('./NotificationAccordion');
jest.unmock('../../stores/NotificationsStore');

import React from 'react';
import { shallow } from 'enzyme';
import NotificationAccordion from './NotificationAccordion';
import testData from '../../stores/NotificationsTestData';
import NotificationsStore from '../../stores/NotificationsStore';

function setup(data) {
  return shallow(<NotificationAccordion notifications={data}/>);
}

describe('NotificationAccordion', () => {
  xit('runs a test', () => {
    const data = NotificationsStore.prepareNotifications(testData);
    const wrapper = setup(data);

    expect(false).toBe('not implemented');
  });
});

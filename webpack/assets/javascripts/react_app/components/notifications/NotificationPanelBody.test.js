jest.unmock('./NotificationPanelBody');

import React from 'react';
import { shallow } from 'enzyme';
import NotificationPanelBody from './NotificationPanelBody';

function setup() {
  return shallow(<NotificationPanelBody />);
}

describe('NotificationPanelBody', () => {
  xit('runs a test', () => {
    setup();
    expect(false).toBe('not implemented');
  });
});

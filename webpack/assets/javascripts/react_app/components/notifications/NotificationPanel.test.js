jest.unmock('./NotificationPanel');

import React from 'react';
import { shallow } from 'enzyme';
import NotificationPanel from './NotificationPanel';

function setup() {
  return shallow(<NotificationPanel />);
}

describe('NotificationPanel', () => {
  xit('runs a test', () => {
    setup();
    expect(false).toBe('not implemented');
  });
});

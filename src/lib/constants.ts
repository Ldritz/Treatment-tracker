export type CageData = {
  block: number;
  row: number;
  treatment: string;
};

export const CAGE_LAYOUT = [
  {
    block: 1,
    rows: [
      ['T1', 'T4', 'T9'],
      ['T6', 'T7', 'T8'],
      ['T2', 'T5', 'T3'],
    ],
  },
  {
    block: 2,
    rows: [
      ['T6', 'T3', 'T5'],
      ['T8', 'T9', 'T4'],
      ['T2', 'T7', 'T1'],
    ],
  },
  {
    block: 3,
    rows: [
      ['T2', 'T7', 'T4'],
      ['T3', 'T6', 'T5'],
      ['T8', 'T9', 'T1'],
    ],
  },
];

export type CageState = 'pending' | 'selected' | 'completed' | 'draft';
